#
#  Copyright (c) 2021 Ronan LE MEILLAT
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#

UNAME_SYSTEM := $(shell uname -s)
ifeq ($(UNAME_SYSTEM), Linux)
	BMDOFXDEVPATH = /opt/resolve/Developer/OpenFX
	CXXFLAGS += -fPIC -Dlinux -D__OPENCL__
	NVCCFLAGS = --compiler-options="-fPIC"
	LDFLAGS = -shared -fvisibility=hidden 
	BUNDLE_DIR = MaxToEquirectPlugin.ofx.bundle/Contents/Linux-x86-64/
	OPENCL_OBJ = MaxToEquirectCLKernel.o
else
	BMDOFXDEVPATH = /Library/Application\ Support/Blackmagic\ Design/DaVinci\ Resolve/Developer/OpenFX
	LDFLAGS = -bundle -fvisibility=hidden -F/Library/Frameworks -framework OpenCL -framework Metal -framework AppKit
	BUNDLE_DIR = MaxToEquirectPlugin.ofx.bundle/Contents/MacOS/
	METAL_OBJ = MaxToEquirectKernel.o
	OPENCL_OBJ = MaxToEquirectCLKernel.o
	METAL_ARM_OBJ = MaxToEquirectKernel-arm.o
	OPENCL_ARM_OBJ = MaxToEquirectCLKernel-arm.o
	APPLE86_64_FLAG =  -target x86_64-apple-macos10.12
	APPLEARM64_FLAG =  -target arm64-apple-macos11
endif

CXXFLAGS += -std=c++11 -fvisibility=hidden -I$(OFXPATH)/include -I$(BMDOFXDEVPATH)/Support/include -I$(BMDOFXDEVPATH)/OpenFX-1.4/include 




MaxToEquirectPlugin.ofx: MaxToEquirectPlugin.o ${OPENCL_OBJ} $(METAL_OBJ) ofxsCore.o ofxsImageEffect.o ofxsInteract.o ofxsLog.o ofxsMultiThread.o ofxsParams.o ofxsProperty.o ofxsPropertyValidation.o
	$(CXX) $^ -o $@ $(LDFLAGS)

MaxToEquirectPlugin-arm.ofx:  MaxToEquirectPlugin-arm.o $(OPENCL_ARM_OBJ) $(METAL_ARM_OBJ) ofxsCore-arm.o ofxsImageEffect-arm.o ofxsInteract-arm.o ofxsLog-arm.o ofxsMultiThread-arm.o ofxsParams-arm.o ofxsProperty-arm.o ofxsPropertyValidation-arm.o
	$(CXX) $(APPLEARM64_FLAG) $^ -o $@ $(LDFLAGS)

MaxToEquirectPlugin.o: MaxToEquirectPlugin.cpp
	$(CXX) $(APPLE86_64_FLAG) -c $< $(CXXFLAGS)

MaxToEquirectPlugin-arm.o: MaxToEquirectPlugin.cpp
	$(CXX) $(APPLEARM64_FLAG) -c $< $(CXXFLAGS) -o $@

MaxToEquirectKernel.h: MaxToEquirectKernel.metal
	python metal2string.py MaxToEquirectKernel.metal MaxToEquirectKernel.h
	
MaxToEquirectKernel.o: MaxToEquirectKernel.mm MaxToEquirectKernel.h
	$(CXX) $(APPLE86_64_FLAG) -c $< $(CXXFLAGS) -o $@

MaxToEquirectKernel-arm.o: MaxToEquirectKernel.mm MaxToEquirectKernel.h
	$(CXX) $(APPLEARM64_FLAG) -c $< $(CXXFLAGS) -o $@
	
MaxToEquirectCLKernel.o: MaxToEquirectCLKernel.cpp MaxToEquirectCLKernel.h
	$(CXX) $(APPLE86_64_FLAG) -c $< $(CXXFLAGS) -o $@

MaxToEquirectCLKernel-arm.o: MaxToEquirectCLKernel.cpp MaxToEquirectCLKernel.h
	$(CXX) $(APPLEARM64_FLAG) -c $< $(CXXFLAGS) -o $@
	
ofxsCore.o: $(BMDOFXDEVPATH)/Support/Library/ofxsCore.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsImageEffect.o: $(BMDOFXDEVPATH)/Support/Library/ofxsImageEffect.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsInteract.o: $(BMDOFXDEVPATH)/Support/Library/ofxsInteract.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsLog.o: $(BMDOFXDEVPATH)/Support/Library/ofxsLog.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsMultiThread.o: $(BMDOFXDEVPATH)/Support/Library/ofxsMultiThread.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsParams.o: $(BMDOFXDEVPATH)/Support/Library/ofxsParams.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsProperty.o: $(BMDOFXDEVPATH)/Support/Library/ofxsProperty.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)

ofxsPropertyValidation.o: $(BMDOFXDEVPATH)/Support/Library/ofxsPropertyValidation.cpp
	$(CXX) $(APPLE86_64_FLAG) -c "$<" $(CXXFLAGS)
	
ofxsCore-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsCore.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsImageEffect-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsImageEffect.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsInteract-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsInteract.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsLog-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsLog.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsMultiThread-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsMultiThread.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsParams-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsParams.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsProperty-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsProperty.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

ofxsPropertyValidation-arm.o: $(BMDOFXDEVPATH)/Support/Library/ofxsPropertyValidation.cpp
	$(CXX) $(APPLEARM64_FLAG) -c "$<" $(CXXFLAGS) -o $@

%.metallib: %.metal
	xcrun -sdk macosx metal -c $< -o $@
	mkdir -p $(BUNDLE_DIR)
	cp $@ $(BUNDLE_DIR)
	
MaxToEquirectCLKernel.h: MaxToEquirectCLKernel.cl
	python ./HardcodeKernel.py MaxToEquirectCLKernel MaxToEquirectCLKernel.cl

clean:
	rm -f *.o *.ofx *.metallib MaxToEquirectCLKernel.h MaxToEquirectKernel.h
	
dist-clean: clean
	rm -fr MaxToEquirectPlugin.ofx.bundle MaxToEquirectPlugin-universal.ofx MaxToEquirectPlugin.ofx MaxToEquirectPlugin-arm.ofx

zip: bundle
	zip -r MaxToEquirectPlugin.ofx.bundle.zip MaxToEquirectPlugin.ofx.bundle
	
ifeq ($(UNAME_SYSTEM), Darwin)
.DEFAULT_GOAL := darwin
	
.PHONY: darwin
darwin: clean zip install
bundle: MaxToEquirectPlugin.ofx MaxToEquirectPlugin-arm.ofx
	mkdir -p $(BUNDLE_DIR)
	lipo -create -output MaxToEquirectPlugin-universal.ofx MaxToEquirectPlugin.ofx MaxToEquirectPlugin-arm.ofx
	mkdir -p $(BUNDLE_DIR)
	cp MaxToEquirectPlugin-universal.ofx $(BUNDLE_DIR)/MaxToEquirectPlugin.ofx
	
install: bundle MaxToEquirectPlugin.ofx MaxToEquirectPlugin-arm.ofx
	cp MaxToEquirectPlugin-universal.ofx $(BUNDLE_DIR)/MaxToEquirectPlugin.ofx
	rm -rf /Library/OFX/Plugins/MaxToEquirectPlugin.ofx.bundle
	cp -a MaxToEquirectPlugin.ofx.bundle /Library/OFX/Plugins/
else
bundle: MaxToEquirectPlugin.ofx
	mkdir -p $(BUNDLE_DIR)
	cp MaxToEquirectPlugin.ofx $(BUNDLE_DIR)/MaxToEquirectPlugin.ofx
	
install: bundle MaxToEquirectPlugin.ofx
	rm -rf /usr/OFX/Plugins/MaxToEquirectPlugin.ofx.bundle
	mkdir -p /usr/OFX/Plugins/
	cp -a MaxToEquirectPlugin.ofx.bundle /usr/OFX/Plugins/
endif
