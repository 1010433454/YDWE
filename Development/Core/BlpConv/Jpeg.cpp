//+-----------------------------------------------------------------------------
//| Included files
//+-----------------------------------------------------------------------------
#include "Jpeg.h"
#include <algorithm>

namespace IMAGE 
{

//+-----------------------------------------------------------------------------
//| Global objects
//+-----------------------------------------------------------------------------
JPEG Jpeg;


//+-----------------------------------------------------------------------------
//| Constructor
//+-----------------------------------------------------------------------------
JPEG::JPEG()
{
	//Empty
}


//+-----------------------------------------------------------------------------
//| Destructor
//+-----------------------------------------------------------------------------
JPEG::~JPEG()
{
	//Empty
}


//+-----------------------------------------------------------------------------
//| Writes JPEG data
//+-----------------------------------------------------------------------------
bool JPEG::Write(const BUFFER& SourceBuffer, BUFFER& TargetBuffer, int Width, int Height, int Quality)
{
	int Stride;
	int RealSize;
	int DummySize;
	BUFFER TempBuffer;
	JSAMPROW Pointer[1];
	jpeg_compress_struct Info;
	jpeg_error_mgr ErrorManager;

	Info.err = jpeg_std_error(&ErrorManager);

	DummySize = ((Width * Height * 4) * 2) + 10000;
	TempBuffer.Resize(DummySize);

	jpeg_create_compress(&Info);

	SetMemoryDestination(&Info, TempBuffer.GetData(), TempBuffer.GetSize());

	Info.image_width = Width;
	Info.image_height = Height;
	Info.input_components = 4;
	Info.in_color_space = JCS_UNKNOWN;

	jpeg_set_defaults(&Info);
	jpeg_set_quality(&Info, Quality, true);
	jpeg_start_compress(&Info, true);

	Stride = Width * 4;
	while(Info.next_scanline < Info.image_height)
	{
		Pointer[0] = reinterpret_cast<JSAMPROW>(const_cast<unsigned char*>(SourceBuffer.GetData(Info.next_scanline * Stride)));
		jpeg_write_scanlines(&Info, Pointer, 1);
	}

	jpeg_finish_compress(&Info);

	RealSize = DummySize - static_cast<int>(Info.dest->free_in_buffer);
	TargetBuffer.Resize(RealSize);

	memcpy(TargetBuffer.GetData(), TempBuffer.GetData(), RealSize);

	jpeg_destroy_compress(&Info);

	return true;
}

//+-----------------------------------------------------------------------------
//| Reads JPEG data
//+-----------------------------------------------------------------------------
bool JPEG::Read(const BUFFER& SourceBuffer, BUFFER& TargetBuffer, unsigned int Width, unsigned int Height)
{
	jpeg_decompress_struct Info;
	jpeg_error_mgr ErrorManager;
	Info.err = jpeg_std_error(&ErrorManager);

	jpeg_create_decompress(&Info);
	SetMemorySource(&Info, const_cast<unsigned char*>(SourceBuffer.GetData()), SourceBuffer.GetSize());
	jpeg_read_header(&Info, true);
	jpeg_start_decompress(&Info);

	if ((Info.output_components != 3) && (Info.output_components != 4))
	{
		LOG("Nr of channels must be 3 or 4!");
		return false;
	}

	TargetBuffer.Resize(Width * Height * 4);
	JSAMPARRAY buffer = (*Info.mem->alloc_sarray)(reinterpret_cast<j_common_ptr>(&Info), JPOOL_IMAGE, Info.output_width * Info.output_components, 1);

	struct rgba_t
	{
		uint8_t r;
		uint8_t g;
		uint8_t b;
		uint8_t a;
	};

	rgba_t* output = reinterpret_cast<rgba_t*>(TargetBuffer.GetData());
	unsigned int minw = (std::min)(Width, Info.output_width);
	for (unsigned int y = 0; y < Height; ++y)
	{
		if (Info.output_scanline < Info.output_height)
		{
			jpeg_read_scanlines(&Info, buffer, 1);

			if (Info.output_components == 3)
			{
				for (unsigned int x = 0; x < minw; ++x)
				{
					output[0].r = buffer[0][3 * x + 0];
					output[0].g = buffer[0][3 * x + 1];
					output[0].b = buffer[0][3 * x + 2];
					output[0].a = 255;
					output++;
				}
			}
			else
			{
				memcpy(output, buffer[0], minw * sizeof rgba_t);
				output += minw;
			}

			if (minw < Width)
			{
				memset(output, 0, (Width - minw) * sizeof rgba_t);
				output += (Width - minw);
			}
		}
		else
		{
			memset(output, 0, Width * sizeof rgba_t);
			output += Width;
		}

	}

	jpeg_destroy_decompress(&Info);

	return true;
}


//+-----------------------------------------------------------------------------
//| Sets the memory source
//+-----------------------------------------------------------------------------
void JPEG::SetMemorySource(jpeg_decompress_struct* Info, unsigned char* Buffer, size_t Size)
{
	JPEG_SOURCE_MANAGER* SourceManager;

	Info->src = reinterpret_cast<jpeg_source_mgr*>((*Info->mem->alloc_small)(reinterpret_cast<j_common_ptr>(Info), JPOOL_PERMANENT, sizeof(JPEG_SOURCE_MANAGER)));
	SourceManager = reinterpret_cast<JPEG_SOURCE_MANAGER*>(Info->src);

	SourceManager->Buffer = reinterpret_cast<JOCTET*>((*Info->mem->alloc_small)(reinterpret_cast<j_common_ptr>(Info), JPOOL_PERMANENT, Size * sizeof(JOCTET)));
	SourceManager->SourceBuffer = Buffer;
	SourceManager->SourceBufferSize = Size;
	SourceManager->Manager.init_source = SourceInit;
	SourceManager->Manager.fill_input_buffer = SourceFill;
	SourceManager->Manager.skip_input_data = SourceSkip;
	SourceManager->Manager.resync_to_restart = jpeg_resync_to_restart;
	SourceManager->Manager.term_source = SourceTerminate;
	SourceManager->Manager.bytes_in_buffer = 0;
	SourceManager->Manager.next_input_byte = NULL;
}


//+-----------------------------------------------------------------------------
//| Sets the memory destination
//+-----------------------------------------------------------------------------
void JPEG::SetMemoryDestination(jpeg_compress_struct* Info, unsigned char* Buffer, size_t Size)
{
	JPEG_DESTINATION_MANAGER* DestinationManager;

	Info->dest = reinterpret_cast<jpeg_destination_mgr*>((*Info->mem->alloc_small)(reinterpret_cast<j_common_ptr>(Info), JPOOL_PERMANENT, sizeof(JPEG_DESTINATION_MANAGER)));
	DestinationManager = reinterpret_cast<JPEG_DESTINATION_MANAGER*>(Info->dest);

	DestinationManager->Buffer = NULL;
	DestinationManager->DestinationBuffer = Buffer;
	DestinationManager->DestinationBufferSize = Size;
	DestinationManager->Manager.init_destination = DestinationInit;
	DestinationManager->Manager.empty_output_buffer = DestinationEmpty;
	DestinationManager->Manager.term_destination = DestinationTerminate;
}


//+-----------------------------------------------------------------------------
//| Initiates the memory source
//+-----------------------------------------------------------------------------
void JPEG::SourceInit(jpeg_decompress_struct* /*Info*/)
{
	//Empty
}


//+-----------------------------------------------------------------------------
//| Fills the memory source
//+-----------------------------------------------------------------------------
boolean JPEG::SourceFill(jpeg_decompress_struct* Info)
{
	JPEG_SOURCE_MANAGER* SourceManager;

	SourceManager = reinterpret_cast<JPEG_SOURCE_MANAGER*>(Info->src);

	SourceManager->Buffer = SourceManager->SourceBuffer;
	SourceManager->Manager.next_input_byte = SourceManager->Buffer;
	SourceManager->Manager.bytes_in_buffer = SourceManager->SourceBufferSize;

	return true;
}


//+-----------------------------------------------------------------------------
//| Skips the memory source
//+-----------------------------------------------------------------------------
void JPEG::SourceSkip(jpeg_decompress_struct* Info, long NrOfBytes)
{
	JPEG_SOURCE_MANAGER* SourceManager;

	SourceManager = reinterpret_cast<JPEG_SOURCE_MANAGER*>(Info->src);

	if(NrOfBytes > 0)
	{
		while(NrOfBytes > static_cast<long>(SourceManager->Manager.bytes_in_buffer))
		{
			NrOfBytes -= static_cast<long>(SourceManager->Manager.bytes_in_buffer);
			SourceFill(Info);
		}

		SourceManager->Manager.next_input_byte += NrOfBytes;
		SourceManager->Manager.bytes_in_buffer -= NrOfBytes;
	}
}


//+-----------------------------------------------------------------------------
//| Terminates the memory source
//+-----------------------------------------------------------------------------
void JPEG::SourceTerminate(jpeg_decompress_struct* /*Info*/)
{
	//Empty
}


//+-----------------------------------------------------------------------------
//| Initiates the memory destination
//+-----------------------------------------------------------------------------
void JPEG::DestinationInit(jpeg_compress_struct* Info)
{
	JPEG_DESTINATION_MANAGER* DestinationManager;

	DestinationManager = reinterpret_cast<JPEG_DESTINATION_MANAGER*>(Info->dest);

	DestinationManager->Buffer = DestinationManager->DestinationBuffer;
	DestinationManager->Manager.next_output_byte = DestinationManager->Buffer;
	DestinationManager->Manager.free_in_buffer = DestinationManager->DestinationBufferSize;
}


//+-----------------------------------------------------------------------------
//| Empties the memory destination
//+-----------------------------------------------------------------------------
boolean JPEG::DestinationEmpty(jpeg_compress_struct* Info)
{
	JPEG_DESTINATION_MANAGER* DestinationManager;

	DestinationManager = reinterpret_cast<JPEG_DESTINATION_MANAGER*>(Info->dest);

	DestinationManager->Manager.next_output_byte = DestinationManager->Buffer;
	DestinationManager->Manager.free_in_buffer = DestinationManager->DestinationBufferSize;

	return true;
}


//+-----------------------------------------------------------------------------
//| Terminates the memory destination
//+-----------------------------------------------------------------------------
void JPEG::DestinationTerminate(jpeg_compress_struct* /*Info*/)
{
	//Empty
}

}
