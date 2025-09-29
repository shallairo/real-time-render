CXX = g++
CXXFLAGS := -std=c++17 -Wall -Wextra -g

OUTPUT := output
SRC := src
INCLUDE := include
LIB := lib

ifeq ($(OS),Windows_NT)
MAIN := main.exe
SOURCEDIRS := $(SRC)
INCLUDEDIRS := $(INCLUDE)
LIBDIRS := $(LIB)
FIXPATH = $(subst /,\,$1)
RM := del /q /f
MD := mkdir
else
MAIN := main
SOURCEDIRS := $(shell find $(SRC) -type d)
INCLUDEDIRS := $(shell find $(INCLUDE) -type d)
LIBDIRS := $(shell find $(LIB) -type d)
FIXPATH = $1
RM := rm -f
MD := mkdir -p
endif

INCLUDES := $(patsubst %,-I%, $(INCLUDEDIRS:%/=%))
INCLUDES += -Iinclude/imgui -Iinclude/imgui/backends

LIBS := $(patsubst %,-L%, $(LIBDIRS:%/=%))

IMGUI_DIR := include/imgui
IMGUI_BACKEND := $(IMGUI_DIR)/backends
IMGUI_SOURCES := \
    $(IMGUI_DIR)/imgui.cpp \
    $(IMGUI_DIR)/imgui_draw.cpp \
    $(IMGUI_DIR)/imgui_widgets.cpp \
	$(IMGUI_DIR)/imgui_tables.cpp \
    $(IMGUI_DIR)/imgui_demo.cpp \
    $(IMGUI_BACKEND)/imgui_impl_glfw.cpp \
    $(IMGUI_BACKEND)/imgui_impl_opengl3.cpp

SOURCES := $(wildcard $(patsubst %,%/*.cpp, $(SOURCEDIRS))) $(IMGUI_SOURCES)
OBJECTS := $(SOURCES:.cpp=.o)
DEPS := $(OBJECTS:.o=.d)
OUTPUTMAIN := $(call FIXPATH,$(OUTPUT)/$(MAIN))

all: $(OUTPUT) $(MAIN)
	@cmd /c echo Build complete!

$(OUTPUT):
	$(MD) $(OUTPUT)

$(MAIN): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $(OUTPUTMAIN) $(OBJECTS) $(LIBS) -lglfw3 -lglad -lgdi32 -lassimp

-include $(filter %.d,$(DEPS))

.cpp.o:
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c -MMD $< -o $@

.PHONY: clean

clean:
	- del /Q *.o *.exe 2>nul
	- del /Q /F $(call FIXPATH,$(OUTPUT)\$(MAIN)) 2>nul
	@cmd /c echo Clean complete!

run: all
	./$(OUTPUTMAIN)
	@cmd /c echo Run complete!


