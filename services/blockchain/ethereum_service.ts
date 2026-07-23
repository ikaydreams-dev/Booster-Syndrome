import { ethers } from 'ethers';

export class EthereumService {
  private provider: ethers.providers.Provider;
  private signer?: ethers.Signer;

  constructor(rpcUrl: string, privateKey?: string) {
    this.provider = new ethers.providers.JsonRpcProvider(rpcUrl);

    if (privateKey) {
      this.signer = new ethers.Wallet(privateKey, this.provider);
    }
  }

  async getBalance(address: string): Promise<string> {
    const balance = await this.provider.getBalance(address);
    return ethers.utils.formatEther(balance);
  }

  async sendTransaction(to: string, amount: string): Promise<string> {
    if (!this.signer) {
      throw new Error('No signer configured');
    }

    const tx = await this.signer.sendTransaction({
      to,
      value: ethers.utils.parseEther(amount),
    });

    const receipt = await tx.wait();
    return receipt.transactionHash;
  }

  async deployContract(abi: any[], bytecode: string, ...args: any[]): Promise<ethers.Contract> {
    if (!this.signer) {
      throw new Error('No signer configured');
    }

    const factory = new ethers.ContractFactory(abi, bytecode, this.signer);
    const contract = await factory.deploy(...args);
    await contract.deployed();

    return contract;
  }

  getContract(address: string, abi: any[]): ethers.Contract {
    return new ethers.Contract(address, abi, this.signer || this.provider);
  }

  async callContractMethod(
    contractAddress: string,
    abi: any[],
    methodName: string,
    ...args: any[]
  ): Promise<any> {
    const contract = this.getContract(contractAddress, abi);
    return contract[methodName](...args);
  }

  async sendContractTransaction(
    contractAddress: string,
    abi: any[],
    methodName: string,
    ...args: any[]
  ): Promise<string> {
    if (!this.signer) {
      throw new Error('No signer configured');
    }

    const contract = this.getContract(contractAddress, abi);
    const tx = await contract[methodName](...args);
    const receipt = await tx.wait();

    return receipt.transactionHash;
  }

  async getTransactionReceipt(txHash: string): Promise<ethers.providers.TransactionReceipt | null> {
    return this.provider.getTransactionReceipt(txHash);
  }

  async getCurrentBlock(): Promise<number> {
    return this.provider.getBlockNumber();
  }

  async getGasPrice(): Promise<string> {
    const gasPrice = await this.provider.getGasPrice();
    return ethers.utils.formatUnits(gasPrice, 'gwei');
  }
}
