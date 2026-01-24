/// Module to handle texture loading
module image;

import std.file, std.conv, std.algorithm, std.range, std.stdio, std.file;

/// Simple struct for loading image/pixel data in PPM format.
struct PPM{

		int mWidth 	= 256;
		int mHeight = 256;
		int mRange  = 255;
		ubyte[] mPixels;

		// Simple PPM image loader
		ubyte[] LoadPPMImage(string filename){
				if(!filename.exists){
						assert(0,"file does not exist:"~filename);
				}

				auto f = File(filename);

				int counter=0;
				bool foundMagicNumber = false;
				bool foundDimensions  = false;
				bool foundRange			  = false;
				foreach(line ; f.byLine()){
						if(line.startsWith("#")){
							continue;
						}
						if(foundMagicNumber == false){
							foundMagicNumber=true;
							if(!line.startsWith("P3")){
								writeln("ERROR! Ill formed PPM image");
							}
								continue;
						}
						if(foundDimensions==false){
							foundDimensions = true;
							char[][] dims = line.split();
							mWidth = line[0].to!int;
							mHeight= line[1].to!int;
								continue;
						}	
						if(foundRange == false){
								foundRange = true;
								mRange = line.to!int;
								continue;
						}
					
						// Handle any whitespace formatting
						char[][] tokens = line.split;
						foreach(token ; tokens){
							mPixels ~= token.to!ubyte;
						}
				}


				// Flip the image pixels from image space to screen space
				//				result = result.reverse;
				// Swizzle the bytes back to RGB order	
				// foreach(rgb ; mPixels.slide(3)){
						//						rgb.reverse;
				//}

				return mPixels;
		}

}
