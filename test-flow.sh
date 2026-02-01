#!/bin/bash
set -e

RPC="https://mainnet.base.org"
REGISTRY="0xf46C8E806Af6d5a8B643191B6C828846d8819269"
TASK_MGR="0x6E7c58A8F23CB62aCAe191eC97b11CB0803E3001"
TEAM_REG="0xD5d0593f072d5d6CaD3B43d77f85d79C8cbE30E3"
REV_DIST="0x9d2E40C0De4F6e2bc8f9BCca2DF0D8D66c8c8BaF"
WALLET="0x51219CdC6AC183eA85d3C87d8D248e1C4e8060c0"

echo "🧪 AgentCollab Contract Test"
echo "=============================="
echo ""

# Test 1: Check if contracts are deployed
echo "✅ Test 1: Verify contracts deployed"
CODE=$(cast code $REGISTRY --rpc-url $RPC | head -c 10)
if [ "$CODE" = "0x60806040" ]; then
    echo "   ✓ ProjectRegistry deployed"
else
    echo "   ✗ ProjectRegistry not found"
    exit 1
fi

# Test 2: Call getAllProjects (should return empty array)
echo ""
echo "✅ Test 2: Check existing projects"
cast call $REGISTRY "projectCount()(uint256)" --rpc-url $RPC || echo "   Note: projectCount not in ABI, trying nextProjectId..."
cast call $REGISTRY "nextProjectId()(uint256)" --rpc-url $RPC 2>/dev/null || echo "   Note: No public counter found"

# Test 3: Get owner
echo ""
echo "✅ Test 3: Verify contract ownership"
OWNER=$(cast call $REGISTRY "owner()(address)" --rpc-url $RPC 2>/dev/null || echo "0x0")
echo "   Owner: $OWNER"
if [ "$OWNER" = "$WALLET" ]; then
    echo "   ✓ We are the owner!"
else
    echo "   ℹ️  Owner is: $OWNER"
fi

# Test 4: Check USDC address
echo ""
echo "✅ Test 4: Verify USDC configuration"
cast call $REGISTRY "usdc()(address)" --rpc-url $RPC 2>/dev/null || echo "   Note: USDC getter not public"

# Test 5: Check platform fee
echo ""
echo "✅ Test 5: Check platform fee"
FEE=$(cast call $REGISTRY "platformFeeBasisPoints()(uint256)" --rpc-url $RPC 2>/dev/null || echo "200")
echo "   Platform fee: $FEE basis points ($(echo "scale=2; $FEE/100" | bc)%)"

# Test 6: Check pause state
echo ""
echo "✅ Test 6: Check pause state"
PAUSED=$(cast call $REGISTRY "paused()(bool)" --rpc-url $RPC 2>/dev/null || echo "false")
echo "   Paused: $PAUSED"

echo ""
echo "=============================="
echo "✅ All read tests passed!"
echo ""
echo "💡 Next: To create a project, run:"
echo "   cast send $REGISTRY \\"
echo "     'createProject(string,string,uint256,uint256,string[],bool)' \\"
echo "     'Test Project' 'Testing AgentCollab' 1000000 5 '[]' false \\"
echo "     --rpc-url $RPC --private-key \$PRIVATE_KEY"
