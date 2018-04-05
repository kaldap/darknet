GPU=1
CUDNN=1
DEBUG=0
CUDNN_FWDONLY=1

# https://github.com/tpruvot/ccminer/wiki/Compatibility
ARCH= -gencode=arch=compute_30,code=\"sm_32,compute_30\" --verbose --target-cpu-architecture ARM -m32

VPATH=./src/:./examples
SLIB=libdarknet.so
ALIB=libdarknet.a
EXEC=darknet
OBJDIR=./obj/

CC=/usr/bin/arm-linux-gnueabihf-gcc-4.8 -march=armv7-a -mthumb -mfpu=neon  -mfloat-abi=hard 
NVCC=/usr/local/cuda-6.5/bin/nvcc -ccbin="/usr/bin/arm-linux-gnueabihf-g++-4.8" --compiler-options="-march=armv7-a -mthumb -mfpu=neon  -mfloat-abi=hard"
AR=/usr/bin/arm-linux-gnueabihf-gcc-ar-4.8
ARFLAGS=rcs
OPTS=-O3
LDFLAGS= -lm -lpthread -lrt -ldl
COMMON= -Iinclude/ -Isrc/ -I3rdparty/include/cudnn
CFLAGS=-Wall -Wno-unknown-pragmas -Wno-unused-result -Wfatal-errors -fPIC

ifeq ($(DEBUG), 1) 
OPTS=-O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I3rdparty/include/cuda
CFLAGS+= -DGPU
LDFLAGS+= -L3rdparty/lib/armhf -lcuda -l:libcudart_static.a -lcublas -lcurand -ldl
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -l:3rdparty/lib/armhf/libcudnn_static.a -l:libculibos.a
endif

ifeq ($(CUDNN_FWDONLY), 1) 
COMMON+= -DFORWARD_ONLY
CFLAGS+= -DFORWARD_ONLY
endif

OBJ=gemm.o utils.o cuda.o deconvolutional_layer.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o detection_layer.o route_layer.o box.o normalization_layer.o avgpool_layer.o layer.o local_layer.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o crnn_layer.o demo.o batchnorm_layer.o region_layer.o reorg_layer.o tree.o  lstm_layer.o
EXECOBJA=captcha.o lsd.o super.o art.o tag.o cifar.o go.o rnn.o segmenter.o regressor.o classifier.o coco.o yolo.o detector.o nightmare.o attention.o darknet.o
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o deconvolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o avgpool_layer_kernels.o
endif

EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

#all: obj backup results $(SLIB) $(ALIB) $(EXEC)
all: obj  results $(SLIB) $(ALIB) $(EXEC)


$(EXEC): $(EXECOBJ) $(ALIB)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ALIB)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS)
	$(CC) $(CFLAGS) -shared $^ -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

obj:
	mkdir -p obj
backup:
	mkdir -p backup
results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(EXECOBJ)

