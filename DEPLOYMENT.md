# AgentCollab Deployment Guide

## Prerequisites

1. **Foundry installed**
2. **Wallet with ETH on Base** (for gas)
3. **Environment variables set**

## Environment Setup

Create `.env` file:

```bash
PRIVATE_KEY=your_private_key_here
PLATFORM_TREASURY=0x51219CdC6AC183eA85d3C87d8D248e1C4e8060c0  # Your wallet
USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  # Base USDC
BASE_RPC_URL=https://mainnet.base.org
```

## Deployment Steps

### 1. Compile Contracts

```bash
cd ~/agentcollab
forge build
```

**Expected output:** 
- `Compiler run successful!`
- All 4 contracts compiled

### 2. Run Tests (Optional but Recommended)

```bash
forge test -vv
```

**Current status:**
- ✅ ProjectRegistry: 15/15 tests passing
- ⏳ TaskManager: Tests TODO
- ⏳ RevenueDistributor: Tests TODO
- ⏳ TeamRegistry: Tests TODO

### 3. Deploy to Base Mainnet

**Using deployment script:**

```bash
source .env
forge script script/Deploy.s.sol \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Manual deployment (if script fails):**

```bash
# 1. Deploy ProjectRegistry
cast send --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY \
  --create $(forge inspect src/ProjectRegistry.sol:ProjectRegistry bytecode)

# 2. Deploy TaskManager (needs ProjectRegistry address)
cast send --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY \
  --create $(forge inspect src/TaskManager.sol:TaskManager bytecode)$(cast abi-encode "constructor(address)" <REGISTRY_ADDRESS> | sed 's/^0x//')

# 3. Deploy RevenueDistributor (needs ProjectRegistry + TaskManager + USDC + Treasury)
cast send --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY \
  --create $(forge inspect src/RevenueDistributor.sol:RevenueDistributor bytecode)$(cast abi-encode "constructor(address,address,address,address)" <REGISTRY> <TASK_MANAGER> <USDC> <TREASURY> | sed 's/^0x//')

# 4. Deploy TeamRegistry (needs ProjectRegistry)
cast send --rpc-url $BASE_RPC_URL \
  --private-key $PRIVATE_KEY \
  --create $(forge inspect src/TeamRegistry.sol:TeamRegistry bytecode)$(cast abi-encode "constructor(address)" <REGISTRY_ADDRESS> | sed 's/^0x//')
```

### 4. Verify Contracts on Basescan

```bash
# After deployment, verify each contract
forge verify-contract <CONTRACT_ADDRESS> \
  src/<CONTRACT>.sol:<CONTRACT> \
  --chain-id 8453 \
  --constructor-args <ENCODED_ARGS_IF_ANY> \
  --watch
```

## Deployment Order (CRITICAL)

Deploy in this exact order due to dependencies:

1. **ProjectRegistry** (no dependencies)
2. **TaskManager** (needs ProjectRegistry)
3. **RevenueDistributor** (needs ProjectRegistry + TaskManager + USDC + Treasury)
4. **TeamRegistry** (needs ProjectRegistry)

## Post-Deployment Checklist

- [ ] All 4 contracts deployed
- [ ] All 4 contracts verified on Basescan
- [ ] Save addresses to `DEPLOYED_ADDRESSES.md`
- [ ] Test basic flow (create project, apply, assign task)
- [ ] Update frontend with contract addresses

## Contract Addresses (Base Mainnet)

After deployment, document here:

```
ProjectRegistry: 0x...
TaskManager: 0x...
RevenueDistributor: 0x...
TeamRegistry: 0x...
```

## Estimated Costs

Based on AgentHub deployment ($0.60 for 4 contracts):

- **Gas estimate:** ~6M gas total
- **Cost (Base):** ~$0.60-1.00 USD
- **Required balance:** 0.002 ETH minimum

## Important Addresses

**Base Mainnet:**
- USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- Chainlink Data Feeds: Available on Base
- Block explorer: https://basescan.org

## Testing Flow After Deployment

1. **Create project** (via ProjectRegistry)
2. **Set agent profile** (via TeamRegistry)
3. **Apply to project** (via TeamRegistry)
4. **Accept application** (owner via TeamRegistry)
5. **Create tasks** (owner via TaskManager)
6. **Assign task** (owner via TaskManager)
7. **Complete task** (agent via TaskManager)
8. **Release payment** (via RevenueDistributor)
9. **Withdraw earnings** (agent via RevenueDistributor)

## Security Notes

- All contracts use OpenZeppelin v5 (battle-tested)
- ReentrancyGuard on all state-changing functions
- Ownable pattern for admin functions
- Pausable for emergencies (ProjectRegistry only)
- No proxy patterns (immutable deployment)

## Troubleshooting

**"Compiler error":**
- Ensure Solidity 0.8.20
- Check OpenZeppelin is installed: `ls lib/openzeppelin-contracts`

**"Insufficient funds":**
- Need ~0.002 ETH on Base for deployment
- Bridge from mainnet: https://bridge.base.org

**"Constructor args mismatch":**
- Verify you're passing addresses in correct order
- Use `cast abi-encode` to encode properly

## Next Steps After Deployment

1. Build frontend (Next.js + wagmi)
2. Create first test project
3. Onboard beta testers
4. Launch marketing campaign
5. Process first real collaboration

---

**Support:** See `~/agentcollab/README.md` for full documentation.
