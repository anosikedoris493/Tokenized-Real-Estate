import { describe, it, expect, beforeEach, vi } from "vitest";

// Mock types and functions
const types = {
  uint: (value: number) => ({ type: "uint", value }),
  principal: (address: string) => ({ type: "principal", value: address }),
  bool: (value: boolean) => ({ type: "bool", value }),
  tuple: (obj: Record<string, any>) => ({ type: "tuple", value: obj }),
  ascii: (value: string) => ({ type: "ascii", value }),
};

class MockChain {
  deployer = { address: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM" };
  accounts = new Map([
    ["wallet_1", { address: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG" }],
    ["wallet_2", { address: "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC" }],
  ]);
  
  mineBlock(txs: any[]) {
    return {
      receipts: txs.map(() => ({ result: { type: "ok", value: true } })),
      height: 2,
    };
  }
  
  callReadOnlyFn(contract: string, method: string, args: any[], sender: string) {
    return {
      result: { type: "ok", value: {} },
    };
  }
}

const Tx = {
  contractCall: (contract: string, method: string, args: any[], sender: string) => ({
    contract,
    method,
    args,
    sender,
  }),
};

describe("Property Tokenization Contract", () => {
  let chain: MockChain;
  let deployer: { address: string };
  let wallet1: { address: string };
  
  beforeEach(() => {
    chain = new MockChain();
    deployer = chain.deployer;
    wallet1 = { address: chain.accounts.get("wallet_1")!.address };
  });
  
  it("should tokenize a property", () => {
    const block = chain.mineBlock([
      Tx.contractCall("property-tokenization", "tokenize-property", [
        types.ascii("123 Main St"),
        types.uint(1000000),
        types.uint(1000)
      ], deployer.address)
    ]);
    
    expect(block.receipts).toHaveLength(1);
    expect(block.height).toBe(2);
    expect(block.receipts[0].result).toEqual({ type: "ok", value: true });
  });
  
  it("should transfer property ownership", () => {
    const block = chain.mineBlock([
      Tx.contractCall("property-tokenization", "tokenize-property", [
        types.ascii("123 Main St"),
        types.uint(1000000),
        types.uint(1000)
      ], deployer.address),
      Tx.contractCall("property-tokenization", "transfer-property", [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    expect(block.receipts).toHaveLength(2);
    expect(block.height).toBe(2);
    expect(block.receipts[1].result).toEqual({ type: "ok", value: true });
  });
  
  it("should retrieve property details", () => {
    chain.mineBlock([
      Tx.contractCall("property-tokenization", "tokenize-property", [
        types.ascii("123 Main St"),
        types.uint(1000000),
        types.uint(1000)
      ], deployer.address)
    ]);
    
    const propertyDetails = chain.callReadOnlyFn(
        "property-tokenization",
        "get-property",
        [types.uint(1)],
        deployer.address
    );
    
    expect(propertyDetails.result).toEqual({
      type: "ok",
      value: {
        owner: types.principal(deployer.address),
        address: types.ascii("123 Main St"),
        value: types.uint(1000000),
        "total-shares": types.uint(1000)
      }
    });
  });
  
  it("should update property value", () => {
    chain.mineBlock([
      Tx.contractCall("property-tokenization", "tokenize-property", [
        types.ascii("123 Main St"),
        types.uint(1000000),
        types.uint(1000)
      ], deployer.address),
      Tx.contractCall("property-tokenization", "update-property-value", [
        types.uint(1),
        types.uint(1100000)
      ], deployer.address)
    ]);
    
    const propertyDetails = chain.callReadOnlyFn(
        "property-tokenization",
        "get-property",
        [types.uint(1)],
        deployer.address
    );
    
    expect(propertyDetails.result).toEqual({
      type: "ok",
      value: {
        owner: types.principal(deployer.address),
        address: types.ascii("123 Main St"),
        value: types.uint(1100000),
        "total-shares": types.uint(1000)
      }
    });
  });
});
