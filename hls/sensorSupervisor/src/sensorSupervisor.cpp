

#include <cstdint>

void execute( volatile uint32_t cfg_port[10], volatile uint32_t* status){

    while(1){
        uint32_t  cmd= *cfg_port;
        switch(cmd){
            case 0x1:    
                *status = 0x40;
                break;
            case 0x2:
                *status = *cfg_port*2;
        }

    }
}