#include "AlienFX_SDK.h"
#include <iostream>

namespace AlienFX_SDK
{
	static struct COMMV1 {
		const byte reset[2] = {0x02 ,0x07};
		const byte loop[2] = {0x02, 0x04};
		const byte color[2] = {0x02, 0x03};
		const byte update[2] = {0x02, 0x05};
		const byte status[2] = {0x02 ,0x06};
		const byte saveGroup[2] = {0x02, 0x08};
		const byte save[2] = {0x02, 0x09};
		//const byte apply[3] = {0x02, 0x1d, 0x03};
		const byte setTempo[2] = {0x02, 0x0e};
		// save group codes saveGroup[2]: 
		// 0x1 - lights
		// 0x2 - ac charge (color, inverse mask after with index 2!) (morph ac-0, 0-ac)
		// 0x5 - ac morph (ac-0)
		// 0x6 - ac morph (ac-batt, batt-ac)
		// 0x7 - batt critical (color, inverse mask after with index 2!) (morph batt-0, 0-batt)
		// 0x8 - batt critical (morph batt-0)
		// 0x9 - batt down (pulse batt-0)
		// 0x2 0x0 - end storage block
		// Reset 0x1 - power & indi, 0x2 - sleep, 0x3 - off, 0x4 - on

	} COMMV1;

	static struct COMMV4 {
		const byte reset[7] = {0x00, 0x03 ,0x21 ,0x00 ,0x01 ,0xff ,0xff};
		const byte colorSel[6] = {0x00, 0x03 ,0x23 ,0x01 ,0x00 ,0x01};
		const byte colorSet[8] = {0x00, 0x03 ,0x24 ,0x00 ,0x07 ,0xd0 ,0x00 ,0xfa};
		const byte update[7] = {0x00, 0x03 ,0x21 ,0x00 ,0x03 ,0x00 ,0xff};
			//{0x00, 0x03 ,0x21 ,0x00 ,0x03 ,0x00 ,0x00};
		const byte setPower[7] = {0x00, 0x03 ,0x22 ,0x00, 0x04, 0x00, 0x5b};
		const byte prepareTurn[4] = {0x00, 0x03, 0x20, 0x2};
		const byte turnOn[3] = {0x00, 0x03, 0x26};
		// 4 = 0x64 - off, 0x41 - dim, 0 - on, 6 - number, 7...31 - IDs (like colorSel)
		// Uknown command codes : 0x20 0x2
	} COMMV4;

	static struct COMMV5 {
		// Start command block
		const byte reset[2] = {0xcc, 0x94};
		const byte status[2] = {0xcc, 0x93};
		const byte colorSet[4] = {0xcc, 0x8c, 0x02, 0x00 };
		const byte loop[3] = {0xcc, 0x8c, 0x13};
		const byte update[4] = {0xcc, 0x8b, 0x01, 0xff}; // fe, 59
		// Seems like row masks: 8c 01 XX - 01, 02, 05, 08, 09, 0e
		// And other masks: 8c XX - 05, 06, 07 (3 in each)
		// first 3 rows bitmask map
		//byte colorSel5[64] = {0xcc,0x8c,05,00,01,01,01,01,01,01,01,01,01,01,01,01,
		//	                    01,  01,01,01,00,00,00,00,01,01,01,01,01,01,01,01,
		//	                    01,  01,01,01,01,01,00,01,00,00,00,00,01,00,01,01,
		//	                    01,  01,01,01,01,01,01,01,01,01,01,01,00,00,00,01};
		//// secnd 4 rows bitmask map
		//byte colorSel6[60] = {0xcc,0x8c,06,00,00,01,01,01,01,01,01,01,01,01,01,01,
		//	                    01,  01,01,00,00,00,00,00,00,01,01,01,01,01,01,01,
		//	                    01,  01,01,01,01,00,01,00,00,00,00,00,01,01,00,01,
		//	                    01,  01,00,00,00,00,01,01,01,01,01,01};
		//// special row bitmask map
		//byte colorSel7[20] = {0xcc,0x8c,07,00,00,00,00,00,00,00,00,00,00,00,00,00,
		//	                    00,  01,01,01};
		//// Unclear, effects?
		//byte colorSel[18] = //{0xcc, 0x8c, 0x01, 0x01, 0x01, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0xff, 0x00, 0x00, 0xff,
		//                    // 0x00, 0x00, 0x01};
		//					//{0xcc, 0x8c, 0x01, 0x01, 0x01, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0xf0, 0xf0, 0x00, 
		//					// 0xf0, 0xf0, 0x01};
		//					{0xcc, 0x8c, 0x01, 0x01, 0x01, 0x00, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0xff, 0x00, 0x00, 
		//					 0xff, 0x00, 0x01};
		const byte turnOnInit[56] = 
		                     {0xcc,0x79,0x7b,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
			                  0xff,0xff,0xff,0xff,0xff,0xff,0x7c,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
			                  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x87,0xff,0xff,0xff,0x00,0xff,
			                  0xff,0xff,0x00,0xff,0xff,0xff,0x00,0x77};
		const byte turnOnInit2[3] = {0xcc,0x79,0x88};
		const byte turnOnSet[4] = {0xcc,0x83,0x38,0x9c};
		// [2],[3]=type, [9]=?, [10..12]=RGB1, [13..15]=RGB2, [16]=?
		const byte setEffect[9] = {0xcc,0x80,0x02,0x07,0x00,0x00,0x01,0x01,0x01};// , 0x00, 0x00, 0xff, 0xff, 0x00, 0xff, 0xff, 0x05
	} COMMV5;

	void Functions::SetMaskAndColor(int index, byte* buffer, byte r1, byte g1, byte b1, byte r2, byte g2, byte b2) {
		unsigned mask = 1 << index;
		buffer[2] = (byte)chain;
		buffer[3] = (mask & 0xFF0000) >> 16;
		buffer[4] = (mask & 0x00FF00) >> 8;
		buffer[5] = (mask & 0x0000FF);
		switch (length) {
		case API_L_V1: 
			buffer[6] = r1;
			buffer[7] = g1;
			buffer[8] = b1;
			break;
		case API_L_V3:
			buffer[6] = r1;
			buffer[7] = g1;
			buffer[8] = b1;
			buffer[9] = r2;
			buffer[10] = g2;
			buffer[11] = b2;
			break;
		case API_L_V2: 
			buffer[6] = (r1 & 0xf0) | ((g1 & 0xf0) >> 4); // 4-bit color!
			buffer[7] = (b1 & 0xf0) | ((r2 & 0xf0) >> 4);
			buffer[8] = (g2 & 0xf0) | ((b2 & 0xf0) >> 4); // 4-bit color!
			break;
		}

		return;
	}

	//Use this method for general devices pid = -1 for full scan
	int Functions::AlienFXInitialize(int vID, int pID, int rpLen)
	{
        managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOReturn ret = IOHIDManagerOpen(managerRef, 0L);
        if (ret != kIOReturnSuccess) {
            //NSLog(@"打开设备失败!");
            return -1;
        } else {
            //NSLog(@"打开设备成功!");
        }
        
        devHandle = NULL;
        afxMap = NULL;
        vid = vID;
        pid = pID;
        length = rpLen;
        
        CFStringRef keys[2];
        CFStringRef values[2];
        CFNumberRef vendorID = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &vid );
        CFNumberRef productID = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &pid );
        keys[0] = CFSTR( kIOHIDVendorIDKey );  values[0] = (CFStringRef) vendorID;
        keys[1] = CFSTR( kIOHIDProductIDKey ); values[1] = (CFStringRef) productID;
        CFDictionaryRef dict = CFDictionaryCreate( kCFAllocatorDefault, (const void **) &keys, (const void **) &values, 1, NULL, NULL);
        IOHIDManagerSetDeviceMatching(managerRef, dict);
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, &HandleDeviceMatchingCallback, this);
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, &HandleDeviceRemovalCallback, this);
        
        CFSetRef allDevices = IOHIDManagerCopyDevices(managerRef);
        CFIndex size = CFSetGetCount(allDevices);
        if (size > 0) {
            IOHIDDeviceRef array[size]; // array of IOHIDDeviceRef
            CFSetGetValues(allDevices, (const void **)array);
            // 拿第一个
            devHandle = array[0];
        } else {
            return -2;
        }
        
        afxMap = new Mappings();
        
        return 0;
	}

    void Functions::HidInputCallback(void * context, IOReturn result, void * sender, IOHIDReportType type, uint32_t reportID, uint8_t * report, CFIndex reportLength) {
        
    }

    void Functions::HandleDeviceMatchingCallback(void * context, IOReturn result, void * sender, IOHIDDeviceRef sdevice) {
        Functions* fun = (Functions*)sender;
        if (fun) {
            fun->devHandle = sdevice;
            char *inputbuffer = (char*)malloc(64);
            IOHIDDeviceRegisterInputReportCallback(fun->devHandle, (uint8_t*)inputbuffer, 64, HidInputCallback, NULL);
        }
    }

    void Functions::HandleDeviceRemovalCallback(void * context, IOReturn result, void * sender, IOHIDDeviceRef sdevice) {
        Functions* fun = (Functions*)sender;
        if (fun) {
            fun->devHandle = NULL;
        }
    }

    bool Functions::HidDSetFeature(byte* buffer, int length) {
        if (!devHandle) {
            return false;
        }
        
        const unsigned char *data_to_send;
        size_t length_to_send;
        //if (buffer[0] == 0x0) {
                /* Not using numbered Reports.
                   Don't send the report number. */
        //        data_to_send = buffer+1;
        //        length_to_send = length-1;
        //    }
        //    else {
                /* Using numbered Reports.
                   Send the Report Number */
                data_to_send = buffer;
                length_to_send = length;
        //    }
        
        IOReturn ret = IOHIDDeviceSetReport(devHandle, kIOHIDReportTypeFeature, buffer[0], (uint8_t*)data_to_send, length_to_send);
        if (ret != kIOReturnSuccess) {
            //NSLog(@"发送数据失败!");
            return false;
        }
        //NSLog(@"发送数据成功!");
        printf("send succ %x:%x:%x:%x:%x:%x:%x:%x:%x:%x, len: %lu\n", data_to_send[0], data_to_send[1], data_to_send[2], data_to_send[3], data_to_send[4], data_to_send[5], data_to_send[6], data_to_send[7], data_to_send[8], data_to_send[9], length_to_send);
        return true;
    }

    bool Functions::HidDSetOutputReport(byte* buffer, int length) {
        if (!devHandle) {
            return false;
        }
        
        const unsigned char *data_to_send;
        size_t length_to_send;
        if (buffer[0] == 0x0) {
                /* Not using numbered Reports.
                   Don't send the report number. */
                data_to_send = buffer+1;
                length_to_send = length-1;
            }
            else {
                /* Using numbered Reports.
                   Send the Report Number */
                data_to_send = buffer;
                length_to_send = length;
            }
        
        IOReturn ret = IOHIDDeviceSetReport(devHandle, kIOHIDReportTypeOutput, buffer[0], (uint8_t*)data_to_send, length_to_send);
        if (ret != kIOReturnSuccess) {
            //NSLog(@"发送数据失败!");
            return false;
        }
        //NSLog(@"发送数据成功!");
        printf("send succ %x:%x:%x:%x:%x:%x:%x:%x:%x:%x, len: %lu\n", data_to_send[0], data_to_send[1], data_to_send[2], data_to_send[3], data_to_send[4], data_to_send[5], data_to_send[6], data_to_send[7], data_to_send[8], data_to_send[9], length_to_send);
        return true;
    }

    bool Functions::HidDGetFeature(byte* buffer, int length) {
        if (!devHandle) {
            return false;
        }
        
        CFIndex len = length;
            IOReturn res = IOHIDDeviceGetReport(devHandle,
                                                kIOHIDReportTypeInput,
                                                buffer[0], /* Report ID */
                                                buffer, &len);
        length = len;
            if (res != kIOReturnSuccess)
                return false;

        return true;
        return true;
    }

    bool Functions::HidDGetInputReport(byte* buffer, int& length) {
        if (!devHandle) {
            return false;
        }
        
        CFIndex len = length;
            IOReturn res = IOHIDDeviceGetReport(devHandle,
                                                kIOHIDReportTypeInput,
                                                buffer[0], /* Report ID */
                                                buffer, &len);
        length = len;
            if (res != kIOReturnSuccess)
                return false;

        return true;
    }

    //bool CloseHandle(IOHIDDeviceRef devHandle) {
    //    //IOHIDDeviceClose(0);
    //    return true;
    //}

	void Functions::Loop()
	{
		byte buffer[MAX_BUFFERSIZE];
		ZeroMemory(buffer, length);
		switch (length) {
		case API_L_V5:
			memcpy(buffer, COMMV5.loop, sizeof(COMMV5.loop));
			HidDSetFeature(buffer, length);
			break;
		//case API_L_V4: {
		//	 //m15 require Input report as a confirmation, not output. 
		//	 //WARNING!!! In latest firmware, this can provide up to 10sec(!) slowdown, so i disable status read. It works without it as well.
		//	HidDSetOutputReport(buffer, length);
		//	 //std::cout << "Status: 0x" << std::hex << (int) BufferN[2] << std::endl;
		//} break;
		case API_L_V3: case API_L_V2: case API_L_V1: {
			memcpy(buffer, COMMV1.loop, sizeof(COMMV1.loop));
			HidDSetOutputReport(buffer, length);
			chain++;
		} break;
		}
	}

	bool Functions::Reset()
	{
		bool result = false;

		byte buffer[MAX_BUFFERSIZE];
		ZeroMemory(buffer, length);
		switch (length) {
		case API_L_V5: {
			// DEBUG!
			memcpy(buffer, COMMV5.reset, sizeof(COMMV5.reset));
			result = HidDSetFeature(buffer, length);
		} break;
		case API_L_V4: {
			memcpy(buffer, COMMV4.reset, sizeof(COMMV4.reset));
			result = HidDSetOutputReport(buffer, length);
		} break;
		case API_L_V3: case API_L_V2: case API_L_V1: {
			memcpy(buffer, COMMV1.reset, sizeof(COMMV1.reset));
			//if (status)
				buffer[2] = 0x04;
			//else
			//	buffer[2] = 0x03;
			result = HidDSetOutputReport(buffer, length);
			AlienfxWaitForReady();
			chain = 1;
		} break;
		}
		inSet = true;
		//std::cout << "Reset!" << std::endl;
		return result;
	}

	bool Functions::UpdateColors()
	{
		bool res = false;
		//if (inSet) {
			byte buffer[MAX_BUFFERSIZE] = {0};
			switch (length) {
			case API_L_V5:
			{
				memcpy(buffer, COMMV5.update, sizeof(COMMV5.update));
				res = HidDSetFeature(buffer, length);
			} break;
			case API_L_V4:
			{
				memcpy(buffer, COMMV4.update, sizeof(COMMV4.update));
				res = HidDSetOutputReport(buffer, length);
			} break;
			case API_L_V3: case API_L_V2: case API_L_V1:
			{
				memcpy(buffer, COMMV1.update, sizeof(COMMV1.update));
				res = HidDSetOutputReport(buffer, length);
				chain = 1;
			} break;
			default: return false;
			}
			//std::cout << "Update!" << std::endl;
			inSet = false;
			sleep(5); // Fix for ultra-fast updates, or next command will fail sometimes.
			return res;
		//}
		//return false;
	}

	bool Functions::SetColor(unsigned index, byte r, byte g, byte b)
	{
		bool val = false;
		// API v4 command - 11,12,13 and 14,15,16 is RGB
		// API v4 command - 4 is index, 5,6,7 is RGB, then circle (8,9,10,11 etc)
		/// API v4 - Buffer[8,9,10] = rgb
		/// But we need to issue 2 commands - light_select and color_set.... this for light_select
		/// Buffer2[5] - COUNT of lights need to be set
		/// Buffer2[6-33] - LightID (index, not mask) - it can be COUNT of them.
		if (!inSet)
			Reset();
		//byte* buffer = new byte[length];
		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V5: {
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV5.colorSet, sizeof(COMMV5.colorSet));
			buffer[4] = index + 1;
			buffer[5] = r;
			buffer[6] = g;
			buffer[7] = b;
			int ret = HidDSetFeature(buffer, length);
			Loop();
			return ret;
		} break;
		case API_L_V4: {
			memcpy(buffer, COMMV4.colorSel, sizeof(COMMV4.colorSel));
			buffer[6] = index;
			val = HidDSetOutputReport(buffer, length);
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV4.colorSet, sizeof(COMMV4.colorSet));
			buffer[8] = r;
			buffer[9] = g;
			buffer[10] = b;
		} break;
		case API_L_V3: case API_L_V2:
		{
			memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
			SetMaskAndColor(index, buffer, r, g, b);
		} break;
		case API_L_V1: {
			memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
			SetMaskAndColor(index, buffer, r, g, b);

			if (index == 5)
			{
				buffer[1] = 0x83;
			}

		} break;
		default: return false;
		}
		val = HidDSetOutputReport(buffer, length);
		Loop();
		return val;
	}

	bool Functions::SetMultiLights(int numLights, UCHAR* lights, int r, int g, int b)
	{
		bool val = false;
		if (!inSet) Reset();
		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V5:
		{
			memcpy(buffer, COMMV5.colorSet, sizeof(COMMV5.colorSet));
			int bPos = 4;
			for (int nc = 0; nc < numLights; nc++) {
				if (bPos < length) {
					buffer[bPos] = lights[nc] + 1;
					buffer[bPos + 1] = r;
					buffer[bPos + 2] = g;
					buffer[bPos + 3] = b;
					bPos += 4;
				} else {
					// Send command and clear buffer...
					val = HidDSetFeature(buffer, length);
					ZeroMemory(buffer, length);
					memcpy(buffer, COMMV5.colorSet, sizeof(COMMV5.colorSet));
					bPos = 4;
				}
			}
			if (bPos > 4)
				val = HidDSetFeature(buffer, length);
			Loop();
		} break;
		case API_L_V4: {
			/// Buffer[5] - Count of lights need to be set
			/// Buffer[6-33] - LightID (index, not mask).
			memcpy(buffer, COMMV4.colorSel, sizeof(COMMV4.colorSel));
			buffer[5] = numLights;
			for (int nc = 0; nc < numLights; nc++)
				buffer[6 + nc] = lights[nc];
			val = HidDSetOutputReport(buffer, length);
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV4.colorSet, sizeof(COMMV4.colorSet));
			buffer[8] = r;
			buffer[9] = g;
			buffer[10] = b;
			val = HidDSetOutputReport(buffer, length);
		} break;
		case API_L_V3: case API_L_V2: case API_L_V1:
		{
			// for older, you just need mix the mask!
			DWORD fmask = 0;
			memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
			SetMaskAndColor(0, buffer, r, g, b);
			for (int nc = 0; nc < numLights; nc++)
				fmask |= 1 << lights[nc];
			buffer[2] = (byte) chain;
			buffer[3] = (byte)((fmask & 0xFF0000) >> 16);
			buffer[4] = (byte)((fmask & 0x00FF00) >> 8);
			buffer[5] = (byte)(fmask & 0x0000FF);
			val = HidDSetOutputReport(buffer, length);
			Loop();
		} break;
		default: {
			for (int nc = 0; nc < numLights; nc++)
				val = SetColor(lights[nc], r, g, b);
		}
		}
		return val;
	}

	bool Functions::SetMultiColor(int size, UCHAR* lights, std::vector<vector<afx_act>> act, bool save) {
		byte buffer[MAX_BUFFERSIZE] = {0};
		bool val = true;
		switch (length) {
		case API_L_V5:
		{
			if (!inSet) Reset();
			memcpy(buffer, COMMV5.colorSet, sizeof(COMMV5.colorSet));
			int bPos = 4;
			for (int nc = 0; nc < size; nc++) {
				if (bPos+4 < length) {
					buffer[bPos] = lights[nc] + 1;
					buffer[bPos + 1] = act[nc][0].r;
					buffer[bPos + 2] = act[nc][0].g;
					buffer[bPos + 3] = act[nc][0].b;
					bPos += 4;
				} else {
					// Send command and clear buffer...
					val = HidDSetFeature(buffer, length);
					ZeroMemory(buffer, length);
					memcpy(buffer, COMMV5.colorSet, sizeof(COMMV5.colorSet));
					bPos = 4;
				}
			}
			if (bPos > 4)
				val = HidDSetFeature(buffer, length);
			Loop();
		}break;
		case API_L_V4:
		{
			if (save) {
				int pwi;
				for (pwi = 0; pwi < size; pwi++)
					if (act[pwi][0].type == AlienFX_A_Power) {
						break;
					}
				if (pwi < size)
					SetPowerAction(lights[pwi], act[pwi][0].r, act[pwi][0].g, act[pwi][0].b,
								   act[pwi][1].r, act[pwi][1].g, act[pwi][1].b,
								   size, lights, &act);
			}
			for (int nc = 0; nc < size; nc++)
				val = SetAction(lights[nc], act[nc]);
		} break;
		case API_L_V1: case API_L_V2: case API_L_V3:
		{
			if (save) {
				// Let's find - do we have power button?
				int pwi;
				for (pwi = 0; pwi < size; pwi++)
					if (act[pwi][0].type == AlienFX_A_Power) {
						break;
					}
				if (pwi < size)
					SetPowerAction(lights[pwi], act[pwi][0].r, act[pwi][0].g, act[pwi][0].b,
									act[pwi][1].r, act[pwi][1].g, act[pwi][1].b,
									size, lights, &act);
				else
					SetPowerAction(-1, 0, 0, 0,
								   0, 0, 0,
								   size, lights, &act);
				//memcpy(buffer, COMMV1.saveGroup, sizeof(COMMV1.saveGroup));
				//buffer[2] = 1;

				//for (int nc = 0; nc < size; nc++) {
				//	HidDSetOutputReport(buffer, length);
				//	val = SetAction(lights[nc], act[nc]);
				//}

				//ZeroMemory(buffer, length);
				//memcpy(buffer, COMMV1.save, sizeof(COMMV1.save));
				//HidDSetOutputReport(buffer, length);
				//Reset();
				//AlienfxWaitForReady();
			}
			for (int nc = 0; nc < size; nc++) {
				HidDSetOutputReport(buffer, length);
				val = SetAction(lights[nc], act[nc]);
			}
		} break;
		}
		return val;
	}

	bool Functions::SetAction(int index, std::vector<afx_act> act)
	{
		bool res = false;

		byte buffer[MAX_BUFFERSIZE] = {0};
		if (act.size() > 0) {
			if (!inSet) Reset();
			switch (length) {
			case API_L_V4:
			{ 
				// Buffer[3], [11] - action type ( 0 - light, 1 - pulse, 2 - morph)
				// Buffer[4], [12] - how long phase keeps
				// Buffer[5], [13] - mode (action type) - 0xd0 - light, 0xdc - pulse, 0xcf - morph, 0xe8 - power morph, 0x82 - spectrum, 0xac - rainbow
				// Buffer[7], [15] - tempo (0xfa - steady)
				// Buffer[8-10]    - rgb
				int bPos = 3;
				memcpy(buffer, COMMV4.colorSel, sizeof(COMMV4.colorSel));
				buffer[6] = index;
				HidDSetOutputReport(buffer, length);
				ZeroMemory(buffer, length);
				memcpy(buffer, COMMV4.colorSet, sizeof(COMMV4.colorSet));
				for (int ca = 0; ca < act.size(); ca++) {
					// 3 actions per record..
					buffer[bPos] = act[ca].type < AlienFX_A_Breathing ? act[ca].type : AlienFX_A_Morph;
					buffer[bPos + 1] = act[ca].time;
					buffer[bPos + 3] = 0;
					buffer[bPos + 4] = act[ca].tempo;
					buffer[bPos + 5] = act[ca].r;
					buffer[bPos + 6] = act[ca].g;
					buffer[bPos + 7] = act[ca].b;
					switch (act[ca].type) {
					case AlienFX_A_Color: buffer[bPos + 2] = 0xd0; buffer[bPos + 4] = 0xfa; break;
					case AlienFX_A_Pulse: buffer[bPos + 2] = 0xdc; break;
					case AlienFX_A_Morph: buffer[bPos + 2] = 0xcf; break;
					case AlienFX_A_Breathing: buffer[bPos + 2] = 0xdc; break;
					case AlienFX_A_Spectrum: buffer[bPos + 2] = 0x82; break;
					case AlienFX_A_Rainbow: buffer[bPos + 2] = 0xac; break;
					case AlienFX_A_Power: buffer[bPos + 2] = 0xe8; break;
					default: buffer[bPos + 2] = 0xd0; buffer[bPos + 4] = 0xfa; buffer[bPos] = AlienFX_A_Color;
					}
					bPos += 8;
					if (bPos+8 >= length) {
						res = HidDSetOutputReport(buffer, length);
						ZeroMemory(buffer, length);
						memcpy(buffer, COMMV4.colorSet, sizeof(COMMV4.colorSet));

						bPos = 3;
					}
				}
				if (bPos != 3) {
					res = HidDSetOutputReport(buffer, length);
				}
				return res;
			} break;
			case API_L_V3: case API_L_V2: case API_L_V1:
			{
				byte* tempBuffer = new byte[length];
				memcpy(tempBuffer, COMMV1.setTempo, sizeof(COMMV1.setTempo));
				tempBuffer[2] = (byte) (((UINT)act[0].tempo << 3 & 0xff00) >> 8);
				tempBuffer[3] = (byte) ((UINT) act[0].tempo << 3 & 0xff);
				tempBuffer[4] = (((UINT) act[0].time << 5 & 0xff00) >> 8);
				tempBuffer[5] = (byte) ((UINT) act[0].time << 5 & 0xff);
				HidDSetOutputReport(tempBuffer, length);
				memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
				for (size_t ca = 0; ca < act.size(); ca++) {
					switch (act[ca].type) {
					case AlienFX_A_Color: 
						buffer[1] = 0x3;
						SetMaskAndColor(index, buffer, act[ca].r, act[ca].g, act[ca].b);
						res = HidDSetOutputReport(buffer, length);
						break;
					case AlienFX_A_Pulse:
					{
						buffer[1] = 0x2;
						SetMaskAndColor(index, buffer, act[ca].r, act[ca].g, act[ca].b);
						res = HidDSetOutputReport(buffer, length);
					} break;
					case AlienFX_A_Morph:
					{
						buffer[1] = 0x1;
						if (ca < act.size() - 1) {
							SetMaskAndColor(index, buffer, act[ca].r, act[ca].g, act[ca].b, act[ca + 1].r, act[ca + 1].g, act[ca + 1].b);
							res = HidDSetOutputReport(buffer, length);
						} else {
							SetMaskAndColor(index, buffer, act[ca].r, act[ca].g, act[ca].b, act[0].r, act[0].g, act[0].b);
							res = HidDSetOutputReport(buffer, length);
						}
					} break;
					default: res = SetColor(index, act[0].r, act[0].g, act[0].b);
					}
				}
				Loop();
			} break;
			}
		}
		return res;
	}

	bool Functions::SetPowerAction(int index, BYTE Red, BYTE Green, BYTE Blue, BYTE Red2, BYTE Green2, BYTE Blue2,
								   int size, UCHAR* lights, std::vector<vector<afx_act>>* act)
	{
		//size_t BytesWritten;

		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V4: { 
			if (!IsDeviceReady()) {
#ifdef _DEBUG
				OutputDebugString(TEXT("Power update - device still not ready\n"));
#endif
				return false;
			}
			// Need to flush query...
			if (inSet) UpdateColors();
			inSet = true;
			// Now set....
			memcpy(buffer, COMMV4.setPower, sizeof(COMMV4.setPower));
			for (BYTE cid = 0x5b; cid < 0x61; cid++) {
				// Init query...
				buffer[6] = cid;
				buffer[4] = 4;
				HidDSetOutputReport(buffer, length);
				buffer[4] = 1;
				HidDSetOutputReport(buffer, length);
				// Now set color by type...
				std::vector<afx_act> act;
				switch (cid) {
				case 0x5b: // Alarm
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, Red, Green, Blue });
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, 0, 0, 0 });
					SetAction(index, act);
					break;
				case 0x5c: // AC power
					act.push_back(afx_act{ AlienFX_A_Color, 0, 0, Red, Green, Blue });
					SetAction(index, act);
					break;
				case 0x5d: // Charge
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, Red, Green, Blue });
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, Red2, Green2, Blue2 });
					SetAction(index, act);
					break;
				case 0x5e: // Low batt
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, Red2, Green2, Blue2 });
					act.push_back(afx_act{ AlienFX_A_Power, 3, 0x64, 0, 0, 0 });
					SetAction(index, act);
					break;
				case 0x5f: // Batt power
					act.push_back(afx_act{ AlienFX_A_Color, 0, 0, Red2, Green2, Blue2 });
					SetAction(index, act);
					break;
				case 0x60: // System sleep?
					act.push_back(afx_act{ AlienFX_A_Color, 0, 0, Red2, Green2, Blue2 });
					SetAction(index, act);
				}
				// And finish
				buffer[4] = 2;
				HidDSetOutputReport(buffer, length);
			}
			// Now (default) color set, if needed...
			buffer[2] = 0x21; buffer[4] = 4; buffer[6] = 0x61;
			HidDSetOutputReport(buffer, length);
			buffer[4] = 1;
			HidDSetOutputReport(buffer, length);
			// Default color set here...
			for (int nc = 0; nc < size; nc++)
				if (lights[nc] != index) {
					SetAction(lights[nc], act->at(nc));
				}
			buffer[4] = 2;
			HidDSetOutputReport(buffer, length);
			// Close set
			buffer[4] = 6;
			HidDSetOutputReport(buffer, length);
			BYTE res = 0;
			while ((res = IsDeviceReady()) && res != 255) sleep(50);
			while (!IsDeviceReady()) sleep(100);
			Reset();
			inSet = false;
		} break;
		case API_L_V3: case API_L_V2: case API_L_V1:
		{
			if (!inSet) Reset();
			//now prepare buffers, we need 2 more for PreSave/Save
			byte* buf_presave = new byte[length],
				* buf_save = new byte[length];
			ZeroMemory(buf_presave, length);
			ZeroMemory(buf_save, length);
			memcpy(buf_presave, COMMV1.saveGroup, sizeof(COMMV1.saveGroup));
			memcpy(buf_save, COMMV1.save, sizeof(COMMV1.save));
			memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));

			// 08 01 - load on boot
			buf_presave[2] = 0x1;
			AlienfxWaitForReady();
			//HidDSetOutputReport(buf_presave, length);
			for (int nc = 0; nc < size; nc++) {
				if (lights[nc] != index) {
					HidDSetOutputReport(buf_presave, length);
					SetAction(lights[nc], act->at(nc));
					//HidDSetOutputReport(buf_presave, length);
					//Loop();
				}
			}
			//SetMaskAndColor(index, buffer, Red, Green, Blue);
			//HidDSetOutputReport(buffer, length);
			//Loop();
			if (size > 0) {
				HidDSetOutputReport(buf_save, length);
				Reset();
			}
	
			if (index >= 0) {
				DWORD invMask = ~((1 << index));// | 0x8000); // what is 8000? Macro?
			// 08 02 - standby
				buf_presave[2] = 0x2;
				buffer[1] = 0x1;
				buffer[2] = 0x1;
				SetMaskAndColor(index, buffer, Red, Green, Blue);
				AlienfxWaitForReady();
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				SetMaskAndColor(index, buffer, 0, 0, 0, Red, Green, Blue);
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_presave, length);
				// now inverse mask... let's constant.
				ZeroMemory(buffer, length);
				memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
				buffer[2] = 0x2;
				buffer[3] = (byte) ((invMask & 0xFF0000) >> 16);
				buffer[4] = (byte) ((invMask & 0x00FF00) >> 8);
				buffer[5] = (byte) (invMask & 0x0000FF);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_save, length);
				Reset();
				// 08 05 - AC power
				buf_presave[2] = 0x5;
				SetMaskAndColor(index, buffer, Red, Green, Blue);
				buffer[2] = 0x1;
				AlienfxWaitForReady();
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_save, length);
				Reset();
				// 08 06 - charge
				buf_presave[2] = 0x6;
				buffer[1] = 0x1;
				buffer[2] = 0x1;
				SetMaskAndColor(index, buffer, Red, Green, Blue, Red2, Green2, Blue2);
				AlienfxWaitForReady();
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				SetMaskAndColor(index, buffer, Red2, Green2, Blue2, Red, Green, Blue);
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_save, length);
				Reset();
				// 08 07 - Battery
				buf_presave[2] = 0x7;
				buffer[1] = 0x3;
				buffer[2] = 0x1;
				SetMaskAndColor(index, buffer, Red2, Green2, Blue2);
				AlienfxWaitForReady();
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				//SetMaskAndColor(index, buffer, 0, 0, 0, Red2, Green2, Blue2);
				//HidDSetOutputReport(buf_presave, length);
				//HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_presave, length);
				// now inverse mask... let's constant.
				ZeroMemory(buffer, length);
				memcpy(buffer, COMMV1.color, sizeof(COMMV1.color));
				buffer[2] = 0x2;
				buffer[3] = (byte) ((invMask & 0xFF0000) >> 16);
				buffer[4] = (byte) ((invMask & 0x00FF00) >> 8);
				buffer[5] = (byte) (invMask & 0x0000FF);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_save, length);
				Reset();
				// 08 08 - battery
				//buf_presave[2] = 0x8;
				//SetMaskAndColor(index, buffer, Red2, Green2, Blue2);
				//buffer[1] = 0x3;
				//buffer[2] = 0x1;
				//AlienfxWaitForReady();
				//HidDSetOutputReport(buf_presave, length);
				//HidDSetOutputReport(buffer, length);
				//HidDSetOutputReport(buf_presave, length);
				//Loop();
				//HidDSetOutputReport(buf_save, length);
				//Reset();
				// 08 09 - batt critical
				buf_presave[2] = 0x9;
				buffer[1] = 0x2;
				AlienfxWaitForReady();
				HidDSetOutputReport(buf_presave, length);
				HidDSetOutputReport(buffer, length);
				HidDSetOutputReport(buf_presave, length);
				Loop();
				HidDSetOutputReport(buf_save, length);
				AlienfxWaitForReady();
				Reset();

				//buffer[2] = 1;
				//buffer[3] = buffer[4] = buffer[5] = buffer[6] = buffer[7] = buffer[8] = 0;
				// fix for immediate change
				buffer[1] = 3;
				SetMaskAndColor(index, buffer, Red, Green, Blue);
				AlienfxWaitForReady();
				HidDSetOutputReport(buffer, length);
				Loop();
				////ZeroMemory(buffer, length);
				////memcpy(buffer, COMMV1.apply, sizeof(COMMV1.apply));
				////HidDSetOutputReport(buffer, length);
				UpdateColors();
				Reset();
				AlienfxWaitForReady();
			}
			delete[] buf_presave; delete[] buf_save;
		} break;
		default:
			// can't set action for old, just use color
			SetColor(index, Red, Green, Blue);
		}
		return true;
	}

	bool Functions::ToggleState(BYTE brightness, vector<mapping>* mappings, bool power) {
        if (! mappings) {
            mappings = afxMap->GetMappings();
        }
        
		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V5:
		{
			//if (inSet) { // not sure... Maybe reset mandatory.
			//	UpdateColors();
			//	Reset();
			//}
			memcpy(buffer, COMMV5.turnOnInit, sizeof(COMMV5.turnOnInit));
			HidDSetFeature(buffer, length);
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV5.turnOnInit2, sizeof(COMMV5.turnOnInit2));
			HidDSetFeature(buffer, length);
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV5.turnOnSet, sizeof(COMMV5.turnOnSet));
			buffer[4] = brightness; // 00..ff
			return HidDSetFeature(buffer, length);
		} break;
		case API_L_V4:
		{
			//if (inSet) UpdateColors();
			memcpy(buffer, COMMV4.prepareTurn, sizeof(COMMV4.prepareTurn));
			HidDSetOutputReport(buffer, length);
			ZeroMemory(buffer, length);
			memcpy(buffer, COMMV4.turnOn, sizeof(COMMV4.turnOn));
			buffer[3] = 0x64 - (((UINT)brightness) * 0x64 / 0xff); // 00..64
            buffer[5] = 6;
            buffer[6] = 0;
            buffer[7] = 1;
            buffer[8] = 2;
            buffer[9] = 3;
            buffer[10] = 4;
            buffer[11] = 5;
			/*byte pos = 6, pindex = 0;
			for (int i = 0; i < mappings->size(); i++) {
				mapping cur = mappings->at(i);
				if (cur.devid == pid && pos < length)
					if (!cur.flags || power) {
						buffer[pos] = (byte)cur.lightid;
						pos++; pindex++;
					}
			}
			buffer[5] = pindex;*/
			return HidDSetOutputReport(buffer, length);
		} break;
		case API_L_V3: case API_L_V1: case API_L_V2:
		{
			int res;
			memcpy(buffer, COMMV1.reset, sizeof(COMMV1.reset));
			if (!brightness) {
				if (power)
					buffer[2] = 0x3;
				else
					buffer[2] = 0x1;
			} else
				buffer[2] = 0x4;

			res = HidDSetOutputReport(buffer, length);
			AlienfxWaitForReady();
			return res;
		} break;
		}
		return false;
	}

	bool Functions::SetGlobalEffects(byte effType, int tempo, afx_act act1, afx_act act2) {
		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V5:
		{
			if (!inSet) Reset();
			memcpy(buffer, COMMV5.setEffect, sizeof(COMMV5.setEffect));
			// [2],[3]=type, [9]=?, [10..12]=RGB1, [13..15]=RGB2, [16]=?
			/*
			0 - color
			1 - reset
			2 - Breathing
			3 - Single-color Wave
			4 - dual color wave 
			5-7 - off?
			8 - pulse
			9 - mix pulse (2 colors)
			a - night rider
			b - lazer
			*/
			buffer[2] = effType;
			// 0-f
			buffer[3] = (BYTE) tempo;
			// ???? 0 or 1 (for color). Stable?
			buffer[9] = 0;
			// colors...
			buffer[10] = act1.r;
			buffer[11] = act1.g;
			buffer[12] = act1.b;
			buffer[13] = act2.r;
			buffer[14] = act2.g;
			buffer[15] = act2.b;
			// ???? 0 for rainbow, 1 for breath, 5 for color.
			buffer[16] = 0x1;
			HidDSetFeature(buffer, length);
			UpdateColors();
			return true;
		} break;
		default: return true;
		}
		return false;
	}

	BYTE Functions::AlienfxGetDeviceStatus()
	{
		byte ret = 0;
		byte buffer[MAX_BUFFERSIZE] = {0};
		switch (length) {
		case API_L_V5:
		{
			memcpy(buffer, COMMV5.status, sizeof(COMMV5.status));
			HidDSetOutputReport(buffer, length);
			buffer[0] = 0xcc;
			if (HidDGetFeature(buffer, length))
				ret = buffer[2];
#ifdef _DEBUG
			//cout << "IO result is ";
			//switch (GetLastError()) {
			//case 0: cout << "Ok."; break;
			//case 1: cout << "Incorrect function"; break;
			//case ERROR_INSUFFICIENT_BUFFER: cout << "Buffer too small!"; break;
			//case ERROR_MORE_DATA: cout << "More data remains!"; break;
			//default: cout << "Unknown (" << GetLastError() << ")";
			//}
			//cout <<  endl;
			//cout << "Status data: " << hex << (int)buffer[2] << "," << (int)buffer[14] << "," << (int)buffer[15] << endl;
#endif
		} break;
		case API_L_V4: {
			if (HidDGetInputReport(buffer, length))
				ret = buffer[2];
		} break;
		case API_L_V3: case API_L_V2: case API_L_V1: {
			memcpy(buffer, COMMV1.status, sizeof(COMMV1.status));
			HidDSetOutputReport(buffer, length);
			
			buffer[0] = 0x01;
			HidDGetInputReport(buffer, length);
			
			if (buffer[0] == 0x01)
				ret = 0x06;
			else ret = buffer[0];
		} break;
		}
#ifdef _DEBUG
		if (ret == 0) {
			OutputDebugString(TEXT("System hangs!\n"));
		}
#endif
		return ret;
	}

	BYTE Functions::AlienfxWaitForReady()
	{
		byte status = AlienFX_SDK::Functions::AlienfxGetDeviceStatus();
		for (int i = 0; i < 10 && (status = AlienFX_SDK::Functions::AlienfxGetDeviceStatus()) != ALIENFX_V2_READY; i++)
		{
			if (status == ALIENFX_V2_RESET)
				return status;
			sleep(50);
		}
		return status;
	}

	BYTE Functions::AlienfxWaitForBusy()
	{

		byte status = AlienFX_SDK::Functions::AlienfxGetDeviceStatus();
		for (int i = 0; i < 10 && (status = AlienFX_SDK::Functions::AlienfxGetDeviceStatus()) != ALIENFX_V2_BUSY; i++)
		{
			if (status == ALIENFX_V2_RESET)
				return status;
			sleep(50);
		}
		return status;
	}

	BYTE Functions::IsDeviceReady()
	{
		int status;
		switch (length) {
		case API_L_V5:
			status = AlienfxGetDeviceStatus();
			return status == ALIENFX_V5_STARTCOMMAND || status == ALIENFX_V5_INCOMMAND;
		case API_L_V4:
			status = AlienfxGetDeviceStatus();
			if (status)
				return status == ALIENFX_V4_READY || status == ALIENFX_V4_WAITUPDATE || status == ALIENFX_V4_WASON;
			else
				return -1;
		case API_L_V3: case API_L_V2: case API_L_V1:
			switch (AlienfxGetDeviceStatus()) {
			case ALIENFX_V2_READY:
				return 1;
			case ALIENFX_V2_BUSY:
				Reset();
				return AlienfxWaitForReady() == ALIENFX_V2_READY;
			case ALIENFX_V2_RESET:
				return AlienfxWaitForReady() == ALIENFX_V2_READY;
			}
			return 0;
		}
		return 1;
	}

	bool Functions::AlienFXClose()
	{
		bool result = true;
		if (devHandle != NULL) {
            IOReturn ret = IOHIDDeviceClose(devHandle, 0L);
            if (ret == kIOReturnSuccess) {
                devHandle = nil;
            } else {
                result = false;
            }
		}
        
        if (managerRef) {
            IOReturn ret = IOHIDManagerClose(managerRef, 0L);
            if (ret == kIOReturnSuccess) {
                managerRef = nil;
            } else {
                result = false;
            }
        }
        
        if (afxMap) {
            delete afxMap;
            afxMap = NULL;
        }

		return result;
	}

    Mappings::~Mappings () {
        groups.clear();
        mappings.clear();
        devices.clear();
    }

/*vector<pair<DWORD,DWORD>> Mappings::AlienFXEnumDevices()
	{
		vector<pair<DWORD,DWORD>> pids;
		GUID guid;
		bool flag = false;
		HANDLE tdevHandle;

		HidD_GetHidGuid(&guid);
		HDEVINFO hDevInfo = SetupDiGetClassDevsA(&guid, NULL, NULL, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
		if (hDevInfo == INVALID_HANDLE_VALUE)
		{
			return pids;
		}
		unsigned int dw = 0;
		SP_DEVICE_INTERFACE_DATA deviceInterfaceData;

		while (!flag)
		{
			deviceInterfaceData.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);
			if (!SetupDiEnumDeviceInterfaces(hDevInfo, NULL, &guid, dw, &deviceInterfaceData))
			{
				flag = true;
				continue;
			}
			dw++;
			DWORD dwRequiredSize = 0;
			if (SetupDiGetDeviceInterfaceDetailW(hDevInfo, &deviceInterfaceData, NULL, 0, &dwRequiredSize, NULL))
			{
				continue;
			}
			std::unique_ptr<SP_DEVICE_INTERFACE_DETAIL_DATA> deviceInterfaceDetailData((SP_DEVICE_INTERFACE_DETAIL_DATA*)new char[dwRequiredSize]);
			deviceInterfaceDetailData->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);
			if (SetupDiGetDeviceInterfaceDetailW(hDevInfo, &deviceInterfaceData, deviceInterfaceDetailData.get(), dwRequiredSize, NULL, NULL))
			{
				std::wstring devicePath = deviceInterfaceDetailData->DevicePath;
				tdevHandle = CreateFile(devicePath.c_str(), GENERIC_WRITE | GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);

				if (tdevHandle != INVALID_HANDLE_VALUE)
				{
					std::unique_ptr<HIDD_ATTRIBUTES> attributes(new HIDD_ATTRIBUTES);
					attributes->Size = sizeof(HIDD_ATTRIBUTES);
					if (HidD_GetAttributes(tattributes.get()))
					{
						for (unsigned i = 0; i < sizeof(vids)/sizeof(DWORD); i++) {
							if (attributes->VendorID == vids[i]) {

								PHIDP_PREPARSED_DATA prep_caps;
								HIDP_CAPS caps;
								HidD_GetPreparsedData(t&prep_caps);
								HidP_GetCaps(prep_caps, &caps);
								HidD_FreePreparsedData(prep_caps);

								if (caps.OutputReportByteLength || caps.Usage == 0xcc) {
#ifdef _DEBUG
									wchar_t buff[2048];
									swprintf_s(buff, 2047, L"Scan: VID: %#x, PID: %#x, Version: %d, Length: %d\n",
											   attributes->VendorID, attributes->ProductID, attributes->VersionNumber, attributes->Size);
									OutputDebugString(buff);
									wprintf(L"%s", buff);
#endif
									pair<DWORD, DWORD> dev;
									dev.first = attributes->VendorID;
									dev.second = attributes->ProductID;
									pids.push_back(dev);
									break;
								}
							}
						}
					}
					CloseHandle(tdevHandle);
				}
			}
		}
		SetupDiDestroyDeviceInfoList(hDevInfo);
		return pids;
	}	*/

	devmap* Mappings::GetDeviceById(int devID, int vid) {
		for (int i = 0; i < devices.size(); i++)
			if (devices[i].devid == devID)
				// vid check, if any
				if (vid && devices[i].vid)
					if (vid == devices[i].vid)
						return &devices[i];
					else
						return nullptr;
				else
					return &devices[i];
		return nullptr;
	}

	mapping* Mappings::GetMappingById(int devID, int LightID) {
		for (int i = 0; i < mappings.size(); i++)
			if (mappings[i].devid == devID && mappings[i].lightid == LightID)
				return &mappings[i];
		return nullptr;
	}

	vector<group>* Mappings::GetGroups() {
		return &groups;
	}

	void Mappings::AddMapping(int devID, int lightID, char* name, int flags) {
		mapping* map;
		if (!(map = GetMappingById(devID, lightID))) {
			map = new mapping;
			map->lightid = lightID;
			map->devid = devID;
			mappings.push_back(*map);
			delete map;
			map = &mappings[mappings.size() - 1];
		}
		if (name != NULL)
			map->name = name;
		if (flags != -1)
			map->flags = flags;
	}

	group* Mappings::GetGroupById(int gID) {
		for (int i = 0; i < groups.size(); i++)
			if (groups[i].gid == gID)
				return &groups[i];
		return nullptr;
	}

	void Mappings::AddGroup(int gID, char* name, int lightNum, DWORD* lightlist) {
		mapping* map;
		group nGroup;
		nGroup.gid = gID;
		nGroup.name = string(name);
		for (int i = 0; i < lightNum/sizeof(DWORD); i+=2) {
			if (map = GetMappingById(lightlist[i], lightlist[i + 1]))
				nGroup.lights.push_back(map);
		}
		groups.push_back(nGroup);
	}
/*
	void Mappings::LoadMappings() {
		DWORD  dwDisposition;
		HKEY   hKey1;

		devices.clear();
		mappings.clear();
		groups.clear();

		RegCreateKeyEx(HKEY_CURRENT_USER,
			TEXT("SOFTWARE\\Alienfx_SDK"),
			0,
			NULL,
			REG_OPTION_NON_VOLATILE,
			KEY_ALL_ACCESS,
			NULL,
			&hKey1,
			&dwDisposition);

		unsigned vindex = 0; mapping map; devmap dev;
		char kName[255], name[255], inarray[255];
		unsigned ret = 0;
		do {
			DWORD len = 255, lend = 255;
			ret = RegEnumValueA(
				hKey1,
				vindex,
				name,
				&len,
				NULL,
				NULL,
				(LPBYTE)inarray,
				&lend
			);
			// get id(s)...
			if (ret == ERROR_SUCCESS) {
				DWORD lID = 0, dID = 0;
				vindex++;
				if (sscanf_s((char*)name, "%d-%d", &dID, &lID) == 2) {
					// light name
					AddMapping(dID, lID, inarray, -1);
					continue;
				}
				if (sscanf_s((char*)name, "Flags%d-%d", &dID, &lID) == 2) {
					// light flags
					AddMapping(dID, lID, NULL, *(unsigned *)inarray);
					continue;
				}
				// New devID format
				if (sscanf_s((char*)name, "Dev#%d_%d", &dev.vid, &dev.devid) == 2) {
					std::string devname(inarray);
					dev.name = devname;
					devices.push_back(dev);
					continue;
				}
				// old devID format
				if (sscanf_s((char*)name, "Dev#%d", &dev.devid) == 1) {
					std::string devname(inarray);
					dev.vid = 0;
					dev.name = devname;
					devices.push_back(dev);
					continue;
				}
			}
		} while (ret == ERROR_SUCCESS);
		vindex = 0;
		do {
			ret = RegEnumKeyA(hKey1, vindex, kName, 255);
			vindex++;
			if (ret == ERROR_SUCCESS) {
				DWORD lID = 0, dID = 0;
				if (sscanf_s((char*) kName, "Light%d-%d", &dID, &lID) == 2) {
					DWORD nameLen = 255, flags;
					RegGetValueA(hKey1, kName, "Name", RRF_RT_REG_SZ, 0, name, &nameLen);
					nameLen = sizeof(DWORD);
					RegGetValueA(hKey1, kName, "Flags", RRF_RT_REG_DWORD, 0, &flags, &nameLen);
					AddMapping(dID, lID, name, flags);
				}
			}
		} while (ret == ERROR_SUCCESS);
		vindex = 0;
		do {
			ret = RegEnumKeyA(hKey1, vindex, kName, 255);
			vindex++;
			if (ret == ERROR_SUCCESS) {
				DWORD gID = 0;
				if (sscanf_s((char*) kName, "Group%d", &gID) == 1) {
					DWORD nameLen = 255, maps[1024];
					RegGetValueA(hKey1, kName, "Name", RRF_RT_REG_SZ, 0, name, &nameLen);
					nameLen = 1024*sizeof(DWORD);
					RegGetValueA(hKey1, kName, "Lights", RRF_RT_REG_DWORD, 0, &maps, &nameLen);
					AddGroup(gID, name, nameLen, maps);
				}
			}
		} while (ret == ERROR_SUCCESS);
		RegCloseKey(hKey1);
	}

	void Mappings::SaveMappings() {
		DWORD  dwDisposition;
		HKEY   hKey1, hKeyS;
		size_t numdevs = devices.size();
		size_t numlights = mappings.size();
		size_t numGroups = groups.size();
		if (numdevs == 0) return;

		// Remove all maps!
		RegDeleteTree(HKEY_CURRENT_USER, TEXT("SOFTWARE\\Alienfx_SDK"));
		
		RegCreateKeyEx(HKEY_CURRENT_USER,
			TEXT("SOFTWARE\\Alienfx_SDK"),
			0,
			NULL,
			REG_OPTION_NON_VOLATILE,
			KEY_ALL_ACCESS,
			NULL,
			&hKey1,
			&dwDisposition);
		//char name[1024];

		for (int i = 0; i < numdevs; i++) {
			//preparing name
			string name = "Dev#" + to_string(devices[i].vid) + "_" + to_string(devices[i].devid);

			RegSetValueExA(
				hKey1,
				name.c_str(),
				0,
				REG_SZ,
				(BYTE*)devices[i].name.c_str(),
				(DWORD)devices[i].name.size()
			);
		}

		for (int i = 0; i < numlights; i++) {
			// new format
			string name = "Light" + to_string(mappings[i].devid) + "-" + to_string(mappings[i].lightid);

			RegCreateKeyA(hKey1, name.c_str(), &hKeyS);

			RegSetValueExA(
				hKeyS,
				"Name",
				0,
				REG_SZ,
				(BYTE*)mappings[i].name.c_str(),
				(DWORD)mappings[i].name.size()
			);

			RegSetValueExA(
				hKeyS,
				"Flags",
				0,
				REG_DWORD,
				(BYTE*)&mappings[i].flags,
				sizeof(DWORD)
			);
			RegCloseKey(hKeyS);

		}

		for (int i = 0; i < numGroups; i++) {
			string name = "Group" + to_string(groups[i].gid);

			RegCreateKeyA(hKey1, name.c_str(), &hKeyS);

			RegSetValueExA(
				hKeyS,
				"Name",
				0,
				REG_SZ,
				(BYTE*)groups[i].name.c_str(),
				(DWORD)groups[i].name.size()
			);

			DWORD* grLights = new DWORD[groups[i].lights.size()*2];

			for (int j = 0; j < groups[i].lights.size(); j++) {
				grLights[j * 2] = groups[i].lights[j]->devid;
				grLights[j * 2 +1] = groups[i].lights[j]->lightid;
			}
			RegSetValueExA(
				hKeyS,
				"Lights",
				0,
				REG_BINARY,
				(BYTE*) grLights,
				2 * (DWORD)groups[i].lights.size() * sizeof(DWORD)
			);

			delete[] grLights;
			RegCloseKey(hKeyS);
		}

		RegCloseKey(hKey1);
	}
 */
	std::vector<mapping>* Mappings::GetMappings()
	{
		return &mappings;
	}

	int Mappings::GetFlags(int devid, int lightid)
	{
		for (int i = 0; i < mappings.size(); i++)
			if (mappings[i].devid == devid && mappings[i].lightid == lightid)
				return mappings[i].flags;
		return 0;
	}

	void Mappings::SetFlags(int devid, int lightid, int flags)
	{
		for (int i = 0; i < mappings.size(); i++)
			if (mappings[i].devid == devid && mappings[i].lightid == lightid) {
				mappings[i].flags = flags;
				return;
			}
	}

	std::vector<devmap>* Mappings::GetDevices()
	{
		return &devices;
	}

	int Functions::GetPID()
	{
		return pid;
	}

	int Functions::GetVid() {
		return vid;
	}

	int Functions::GetVersion()
	{
		switch (length) {
		case API_L_V5: return 5; break;
		case API_L_V4: return 4; break;
		case API_L_V3: return 3; break;
		case API_L_V2: return 2; break;
		case API_L_V1: return 1; break;
		default: return 0;
		}
		return length;
	}

}


