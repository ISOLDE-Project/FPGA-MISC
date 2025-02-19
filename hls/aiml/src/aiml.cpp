

#include <cstdint>

void execute( volatile uint32_t cfg_port1[10],  volatile uint32_t cfg_port2[10], volatile uint32_t* data_port){

    while(1){
        uint32_t  cmd= *cfg_port1;
        switch(cmd){
            case 0x1:    
                *data_port = 0x40;
                break;
            case 0x2:
                *data_port = *cfg_port2*2;
        }

    }
}