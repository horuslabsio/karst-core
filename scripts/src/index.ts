import {WalletClient, TBAChainID, TBAVersion, TokenboundClient} from "starknet-tokenbound-sdk"

const walletClient: WalletClient = {
    address: "0x07EadF65B6D96A7DEbB36380fF936F6701a053Be8f2824D6293f188fA542C502",
    privateKey: process.env.ACCOUNT_TWO_PRIVATE_KEY!,
  };
  const options = {
    walletClient: walletClient,
    chain_id: TBAChainID.sepolia,
    version: TBAVersion.V2,
    jsonRPC: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/LSOcLfeCY8c4ovUNnDNX4YJhkMpsVD5F",
  };
  const tokenbound = new TokenboundClient(options);
export default  tokenbound