SRC := $(wildcard src/*.cpp)
GEN := src/scanner.cpp src/parser.cpp src/parser.h src/parser.output
OBJ := $(addprefix obj/,$(notdir $(SRC:.cpp=.o))) obj/scanner.o obj/parser.o
BIN := c-

BFLAGS := --verbose --report=all -Wall -Werror
CFLAGS := -Wall -Wextra -Wno-switch -DYYDEBUG
LFLAGS := $(CFLAGS)

.PHONY : clean submit

$(BIN) : $(OBJ)
	g++ $(LFLAGS) -o $@ $^

$(OBJ) : $(GEN)

src/scanner.cpp : src/scanner.l src/parser.h
	flex --outfile=src/scanner.cpp src/scanner.l

src/parser.cpp src/parser.h : src/parser.y
	bison $(BFLAGS) --defines=src/parser.h --output=src/parser.cpp src/parser.y

obj/%.o : src/%.cpp $(GEN)
	g++ $(CFLAGS) -c -o $@ $<

clean : 
	rm -rf $(GEN)
	rm -rf $(OBJ)
	rm -rf $(BIN)

tar : clean
	tar -cf fabe0940.tar makefile src obj

submit : tar
	curl --verbose -X POST \
		-F student=fabel -F assignment="CS445 F16 Assignment 4" \
		-F "submittedfile=@fabe0940.tar" \
		"http://ec2-52-89-93-46.us-west-2.compute.amazonaws.com/cgi-bin/fileCapture.py"
