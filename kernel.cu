#include "common.h"
#include "cpu_bitmap.h"

#define DIM 100
#define INDEX(x, y) ((x)+(y)*DIM)

__device__ int step( int i, int j, unsigned char *col ) {

	int aliveNeighbours = 0;
	if (i != 0 && j != 0)
		aliveNeighbours += (col[4*INDEX(i - 1,j - 1)]) ? 1 : 0;
	if (i != 0)
	{
		aliveNeighbours += (col[4*INDEX(i - 1,j)]) ? 1 : 0;
		aliveNeighbours += (col[4*INDEX(i - 1,j + 1)]) ? 1 : 0;
	}
	if (j != 0)
	{
		aliveNeighbours += (col[4*INDEX(i + 1,j - 1)]) ? 1 : 0;
		aliveNeighbours += (col[4*INDEX(i,j - 1)]) ? 1 : 0;
	}
	if (j + 1 < DIM)
	{
		aliveNeighbours += (col[4*INDEX(i,j + 1)]) ? 1 : 0;
		if (i + 1 < DIM)
			aliveNeighbours += (col[4*INDEX(i + 1,j + 1)]) ? 1 : 0;
	}
	if (i + 1 < DIM)
		aliveNeighbours += (col[4*INDEX(i + 1,j)]) ? 1 : 0;

	if (col[4*INDEX(i,j)] && aliveNeighbours > 1 && aliveNeighbours < 4)
		return 1;
	if (!col[4*INDEX(i,j)] && aliveNeighbours > 2 && aliveNeighbours < 4)
		return 1;
	return 0;
 
}

//__global__ void kernel( unsigned char *ptr ) {
//    // Odwzorowanie z blockIdx na położenie piksela
//    int x = blockIdx.x;
//    int y = blockIdx.y;
//    int offset = x + y * gridDim.x;
//
//    // Obliczenie wartości dla tego miejsca
//    int isAlive = step( x, y, ptr );
//    ptr[offset*4 + 0] = 255 * isAlive;	//Red
//    ptr[offset*4 + 1] = 255 * isAlive;	//Green
//    ptr[offset*4 + 2] = 255 * isAlive;	//Blue
//    ptr[offset*4 + 3] = 255 * isAlive;	//Alpha
//}

__global__ void setBoard( unsigned char *ptr ) {
    // Odwzorowanie z blockIdx na położenie piksela
    int x = blockIdx.x;
    int y = blockIdx.y;
    int offset = x + y * gridDim.x;

    // Obliczenie wartości dla tego miejsca
    int isAlive = (offset % 2 + y % 2) %2;
    ptr[offset*4 + 0] = 255 * isAlive;	//Red
    ptr[offset*4 + 1] = 255 * isAlive;	//Green
    ptr[offset*4 + 2] = 255 * isAlive;	//Blue
    ptr[offset*4 + 3] = 255 * isAlive;
}

// Wartości wymagane przez procedurę aktualizującą
struct DataBlock {
    unsigned char   *dev_bitmap;
};

int main( void ) {
    DataBlock   data;
    CPUBitmap bitmap( DIM, DIM, &data );
    unsigned char    *dev_bitmap;

    HANDLE_ERROR( cudaMalloc( (void**)&dev_bitmap, bitmap.image_size() ) );
    data.dev_bitmap = dev_bitmap;

    dim3    grid(DIM,DIM);
	setBoard<<<grid,1>>>( dev_bitmap );
//    kernel<<<grid,1>>>( dev_bitmap );

    HANDLE_ERROR( cudaMemcpy( bitmap.get_ptr(), dev_bitmap,
                              bitmap.image_size(),
                              cudaMemcpyDeviceToHost ) );
                              
    HANDLE_ERROR( cudaFree( dev_bitmap ) );
                              
    bitmap.display_and_exit();
}

