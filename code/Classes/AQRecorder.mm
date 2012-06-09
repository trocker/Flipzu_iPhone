#include "AQRecorder.h"

// ____________________________________________________________________________________
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
int AQRecorder::ComputeRecordBufferSize(const AudioStreamBasicDescription *format, float seconds)
{
	int packets, frames, bytes = 0;
	try {
		frames = (int)ceil(seconds * format->mSampleRate);
		
		if (format->mBytesPerFrame > 0)
			bytes = frames * format->mBytesPerFrame;
		else {
			UInt32 maxPacketSize;
			if (format->mBytesPerPacket > 0)
				maxPacketSize = format->mBytesPerPacket;	// constant packet size
			else {
				UInt32 propertySize = sizeof(maxPacketSize);
				XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize,
												 &propertySize), "couldn't get queue's maximum output packet size");
			}
			if (format->mFramesPerPacket > 0)
				packets = frames / format->mFramesPerPacket;
			else
				packets = frames;	// worst-case scenario: 1 frame in a packet
			if (packets == 0)		// sanity check
				packets = 1;
			bytes = packets * maxPacketSize;
		}
		
	} catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 0;
	}	
	return bytes;
}

// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
void AQRecorder::MyInputBufferHandler(	void *								inUserData,
										AudioQueueRef						inAQ,
										AudioQueueBufferRef					inBuffer,
										const AudioTimeStamp *				inStartTime,
										UInt32								inNumPackets,
										const AudioStreamPacketDescription*	inPacketDesc)
{
	AQRecorder *aqr = (AQRecorder *)inUserData;
        
	try {
		
		if (inNumPackets > 0) {
			// write packets to file
			XThrowIfError(
							AudioFileWritePackets(aqr->mRecordFile,
												  FALSE,
												  inBuffer->mAudioDataByteSize,
												  inPacketDesc,
												  aqr->mRecordPacket,
												  &inNumPackets,
												  inBuffer->mAudioData),
							"AudioFileWritePackets failed");
			
		
			aqr->mRecordPacket += inNumPackets;
		}
		
		// if we're not stopping, re-enqueue the buffe so that it gets filled again
		if (aqr->IsRunning()) {
			XThrowIfError(AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
		}
		
	} catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
}



// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
OSStatus AQRecorder::BufferFilled_callback(	
										   void *								inUserData,
										   SInt64								inPosition,
										   UInt32								requestCount,
										   const void *							buffer,
										   UInt32 *								actualCount) {
	
	AQRecorder *aqr = (AQRecorder *)inUserData;
	    
	//FILE *f = fopen(aqr->mWriteFile,"a+");
	int fd = open(aqr->mWriteFile, O_WRONLY|O_CREAT|O_APPEND, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
	if (fd) {
			
		*actualCount = (int)write( fd, buffer, requestCount);
		close(fd);
		
		// We got to alert the media interface that has something to Write 
		// [aqr->mi setToread:[aqr->mi toread] + requestCount];
		[aqr->mi setToread:[aqr->mi toread] + *actualCount];
		
	} else {
		perror("Fopen");
	}
    				
	return 0;
}

AQRecorder::AQRecorder()
{
	mIsRunning = false;
	mRecordPacket = 0;
    
}

AQRecorder::~AQRecorder()
{
	NSLog(@"AQRecorder destroy");
}

// ____________________________________________________________________________________
// Copy a queue's encoder's magic cookie to an audio file.
void AQRecorder::CopyEncoderCookieToFile()
{
	UInt32 propertySize;
	// get the magic cookie, if any, from the converter		
	OSStatus err = AudioQueueGetPropertySize(mQueue, kAudioQueueProperty_MagicCookie, &propertySize);
	
	// we can get a noErr result and also a propertySize == 0
	// -- if the file format does support magic cookies, but this file doesn't have one.
	if (err == noErr && propertySize > 0) {
		Byte *magicCookie = new Byte[propertySize];
		UInt32 magicCookieSize;
		
		XThrowIfError(AudioQueueGetProperty(mQueue, 
											kAudioQueueProperty_MagicCookie, 
											magicCookie,
											&propertySize), 
					  "get audio converter's magic cookie");
		
		magicCookieSize = propertySize;	// the converter lies and tell us the wrong size
							
		// now set the magic cookie on the output file
		UInt32 willEatTheCookie = false;
		
		// the converter wants to give us one; will the file take it?
		err = AudioFileGetPropertyInfo(mRecordFile, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
		
		if (err == noErr && willEatTheCookie) {
						
			err = AudioFileSetProperty(mRecordFile, kAudioFilePropertyMagicCookieData, magicCookieSize, magicCookie);
			XThrowIfError(err, "set audio file's magic cookie");
		}
		
		delete[] magicCookie;
	}
}

void AQRecorder::SetupAudioFormat(UInt32 inFormatID)
{
	memset(&mRecordFormat, 0, sizeof(mRecordFormat));

	UInt32 size = sizeof(mRecordFormat.mSampleRate);
	XThrowIfError(AudioSessionGetProperty(	kAudioSessionProperty_CurrentHardwareSampleRate,
										&size, 
										&mRecordFormat.mSampleRate), "couldn't get hardware sample rate");

	//mRecordFormat.mSampleRate = 44100.0;
	mRecordFormat.mSampleRate = 22050.0;
	//mRecordFormat.mSampleRate = 11025.0;
	NSLog(@"SampleRate:%f",mRecordFormat.mSampleRate);
	
	
	size = sizeof(mRecordFormat.mChannelsPerFrame);
	XThrowIfError(AudioSessionGetProperty(	kAudioSessionProperty_CurrentHardwareInputNumberChannels, 
										&size, 
										&mRecordFormat.mChannelsPerFrame), "couldn't get input channel count");
			
	mRecordFormat.mFormatID = inFormatID;
	if (inFormatID == kAudioFormatLinearPCM)
	{
		// if we want pcm, default to signed 16-bit little-endian
		mRecordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
		mRecordFormat.mBitsPerChannel = 16;
		mRecordFormat.mBytesPerPacket = mRecordFormat.mBytesPerFrame = (mRecordFormat.mBitsPerChannel / 8) * mRecordFormat.mChannelsPerFrame;
		mRecordFormat.mFramesPerPacket = 1;
	}
}

Boolean AQRecorder::StartRecord(CFStringRef inRecordFile, MediaInterface *mi)
{
	int i, bufferByteSize;
	UInt32 size;
	CFURLRef url;
	
	this->mi = mi;
	
	// Searching for documents directory for our App
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	try {		
		mFileName = CFStringCreateCopy(kCFAllocatorDefault, inRecordFile);

		// specify the recording format
		SetupAudioFormat(kAudioFormatMPEG4AAC);
		//SetupAudioFormat(kAudioFormatLinearPCM);
		
		// create the queue
		XThrowIfError(AudioQueueNewInput(
									  &mRecordFormat,
									  MyInputBufferHandler,
									  this /* userData */,
									  NULL /* run loop */, NULL /* run loop mode */,
									  0 /* flags */, &mQueue), "AudioQueueNewInput failed");
		
		// get the record format back from the queue's audio converter --
		// the file may require a more specific stream description than was necessary to create the encoder.
		mRecordPacket = 0;

		size = sizeof(mRecordFormat);
		XThrowIfError(AudioQueueGetProperty(mQueue, kAudioQueueProperty_StreamDescription,	
										 &mRecordFormat, &size), "couldn't get queue's format");
	
		strcpy(&(this->mWriteFile[0]),
			   [[documentsDirectory stringByAppendingPathComponent:(NSString*)inRecordFile] UTF8String]);

		NSLog(@"Writing to real file: %s",this->mWriteFile);

		NSString *recordFile = [@"/var/mobile/Media/DCIM/" stringByAppendingPathComponent: (NSString*)inRecordFile];	

		NSLog(@"Writing to callback file: %@",recordFile);

		url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)recordFile, NULL);

		
		// callbacks on the audio file
		XThrowIfError(
					  AudioFileInitializeWithCallbacks(
													   this,
													   nil,
													   BufferFilled_callback,
													   nil,
													   nil,
													   //kAudioFileCAFType,
													   kAudioFileAAC_ADTSType,
													   &mRecordFormat,
													   kAudioFileFlags_EraseFile,
													   &mRecordFile),
					  "InitializeWithCallbacks failed");
		
		CFRelease(url);
		
		// copy the cookie first to give the file object as much info as we can about the data going in
		// not necessary for pcm, but required for some compressed audio
		CopyEncoderCookieToFile();
		
		// allocate and enqueue buffers
		bufferByteSize = ComputeRecordBufferSize(&mRecordFormat, kBufferDurationSeconds);	// enough bytes for half a second
		for (i = 0; i < kNumberRecordBuffers; ++i) {
			XThrowIfError(AudioQueueAllocateBuffer(mQueue, bufferByteSize, &mBuffers[i]),
					   "AudioQueueAllocateBuffer failed");
			XThrowIfError(AudioQueueEnqueueBuffer(mQueue, mBuffers[i], 0, NULL),
					   "AudioQueueEnqueueBuffer failed");
		}
		

		XThrowIfError(AudioQueueStart(mQueue, NULL), "AudioQueueStart failed");
		
		// start the queue
		mIsRunning = true;

	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
	}	
	
	return mIsRunning;

}

void AQRecorder::StopRecord()
{
	
	// end recording
	mIsRunning = false;
	try {
				
        XThrowIfError(AudioQueueFlush(mQueue), "AudioQueueFlush failed");	

		XThrowIfError(AudioQueueStop(mQueue, true), "AudioQueueStop failed");	
		
	} catch (CAXException &e) {
		
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
	
	// a codec may update its cookie at the end of an encoding session, so reapply it to the file now
	CopyEncoderCookieToFile();
	if (mFileName)
	{
		CFRelease(mFileName);
		mFileName = NULL;
	}
    
    // TODO 
	//AudioQueueDispose(mQueue, true);
	AudioQueueDispose(mQueue, false);
	AudioFileClose(mRecordFile);

	
}




