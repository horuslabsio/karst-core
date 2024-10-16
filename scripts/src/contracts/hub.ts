import tokenbound from "../index";
import {KARST_HUB_CONTRACT_ADDRESS, PROFILE_ADDRESS_ONE, PROFILE_ADDRESS_TWO} from "../helpers/constants"
import { Call } from "starknet-tokenbound-sdk";


const execute_unfollow = async() =>{
    let call:Call = {
        to:KARST_HUB_CONTRACT_ADDRESS,
        selector:"0x70cb483ff70f4401877815e8a7bada80205df630fe0d8157b4e458f4e5114e",
        calldata:[1, PROFILE_ADDRESS_ONE]
        }
        try {
            const Resp = await tokenbound?.execute(PROFILE_ADDRESS_TWO, [call])
            console.log('execution-response=:', Resp)
        } catch (error) {
            console.log(error)
        }
    
}

execute_unfollow()