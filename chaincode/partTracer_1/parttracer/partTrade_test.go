package parttracer

import(
	"testing"
	"github.com/golang/protobuf/ptypes"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-chaincode-go/shimtest/mock"
	"github.com/hyperledger/fabric-chaincode-go/pkg/cid"
	"github.com/stretchr/testify/assert"
)

// Mock Implementations
type mockClientIdentity struct{
	cid.ClientIdentity
}

func (mci *mockClientIdentity) GetMSPID() (string, error) {
	return "", nil
}

type MockTransactionContext struct {
	contractapi.TransactionContext
}

func TestAddPart(t *testing.T) {
	var err error
	var partID string
	contract := new(PartTrade)
	
	mockStub := shimtest.NewMockStub("mockstub", new (mock.Chaincode) )

	ctx := new(MockTransactionContext)
	ctx.SetClientIdentity(new (mockClientIdentity))
	ctx.SetStub(mockStub)

	expectedPart := Part{ PartID: "engine_1", PartName: "engine", Description: "Two seater Private Plane", QuotePrice: 1000, Manufacturer:"maker", Owner:"owner" }
	expectedPart.SetNew()

	tim, _ := ctx.GetStub().GetTxTimestamp()
	txTime, _ :=  ptypes.Timestamp(tim)
	expectedPart.EventTime = txTime.Format("2006-01-02_5:04:05")
	
	txID := "mockTxID"
	// Test Success case
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 10000, "maker")
	mockStub.MockTransactionEnd(txID)
	
	assert.Nil(t, err, "should not error when add part does not error")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")

	// Test invalid PartID
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "", "engine", "Two seater Private Plane", 10000, "maker")
	assert.EqualError(t, err, "Invalid part ID", "should return error when add part fails")
	assert.Equal(t,"",partID, "PartID should be empty")
	mockStub.MockTransactionEnd(txID)

	// Test invalid PartName
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "", "Two seater Private Plane", 10000, "maker")
	assert.EqualError(t, err, "Invalid part Name info", "should return error when add part fails")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")
	mockStub.MockTransactionEnd(txID)

	// Test invalid Description
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "", 10000, "maker")
	assert.EqualError(t, err, "Invalid description ", "should return error when add part fails")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")
	mockStub.MockTransactionEnd(txID)

	// Test invalid QuotePrice
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 0, "maker")
	assert.EqualError(t, err, "Invalid quote price info", "should return error when add part fails")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")
	mockStub.MockTransactionEnd(txID)

	// Test invalid Manufacturer
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 10000, "")
	assert.EqualError(t, err, "Invalid manufacturer info", "should return error when add part fails")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")
	mockStub.MockTransactionEnd(txID)

	// Test adding an already esisting part
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 10000, "maker")
	mockStub.MockTransactionEnd(txID)
	
	assert.EqualError(t, err, "engine_1 : already exists", "should return error when add part fails")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")
}

func TestQueryPart(t *testing.T){

	var err error
	var part *Part
	var partID string

	contract := new(PartTrade)
	
	mockStub := shimtest.NewMockStub("mockstub", new (mock.Chaincode) )

	ctx := new(MockTransactionContext)
	ctx.SetClientIdentity(new (mockClientIdentity))
	ctx.SetStub(mockStub)

	expectedPart := Part{ PartID: "engine_1", PartName: "engine", Description: "Two seater Private Plane", QuotePrice: 1000, Manufacturer:"maker", Owner:"owner" }
	expectedPart.SetNew()

	tim, _ := ctx.GetStub().GetTxTimestamp()
	txTime, _ :=  ptypes.Timestamp(tim)
	expectedPart.EventTime = txTime.Format("2006-01-02_5:04:05")
	
	txID := "mockTxID"
	// Adding Part for Query
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 10000, "maker")
	mockStub.MockTransactionEnd(txID)
	
	assert.Nil(t, err, "should not error when add part")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")

	// Test Query Success
	part, err = contract.QueryPart(ctx,"engine_1")
	assert.Nil(t, err, "should not error when query part")
	assert.Equal(t, "engine_1", part.PartID, "should update the PartID of the Part")
	assert.Equal(t, "engine", part.PartName, "should update the PartName of the Part")
	assert.Equal(t, "Two seater Private Plane", part.Description, "should update the Description of the Part")
	assert.Equal(t, uint32(10000), part.QuotePrice, "should update the QuotePrice of the Part")
	assert.True(t, part.IsNew(), "should update the QuotePrice of the Part")
	assert.Equal(t,"",part.Owner,"Owner set to nil by default")

	// Test Part does not exist
	part, err = contract.QueryPart(ctx,"engine_5")
	assert.Nil(t, part, "should return nil part on Query")
	assert.EqualError(t, err, "engine_5 : does not exist", "should return error when add part fails")

	// Test for Invalid PardID
	part, err = contract.QueryPart(ctx,"")
	assert.Nil(t, part, "should return nil part on Query")
	assert.EqualError(t, err, "Invalid part ID", "should return error when Queried with empty partID")
}

func TestSellPart(t *testing.T){

	var err error
	var part *Part
	var partID string

	contract := new(PartTrade)
	
	mockStub := shimtest.NewMockStub("mockstub", new (mock.Chaincode) )

	ctx := new(MockTransactionContext)
	ctx.SetClientIdentity(new (mockClientIdentity))
	ctx.SetStub(mockStub)

	expectedPart := Part{ PartID: "engine_1", PartName: "engine", Description: "Two seater Private Plane", QuotePrice: 1000, Manufacturer:"maker", Owner:"owner" }
	expectedPart.SetNew()

	tim, _ := ctx.GetStub().GetTxTimestamp()
	txTime, _ :=  ptypes.Timestamp(tim)
	expectedPart.EventTime = txTime.Format("2006-01-02_5:04:05")
	
	txID := "mockTxID"
	// Adding Part for Query
	mockStub.MockTransactionStart(txID)
	partID, err = contract.AddPart(ctx, "engine_1", "engine", "Two seater Private Plane", 10000, "maker")
	mockStub.MockTransactionEnd(txID)
	assert.Nil(t, err, "should not error when add part")
	assert.Equal(t, "engine_1", partID, "partID should be the engine_1")

	// Success Sell
	mockStub.MockTransactionStart(txID)
	part, err = contract.SellPart(ctx, "engine_1", "", 9999)
	mockStub.MockTransactionEnd(txID)
	assert.Nil(t, err, "should not error when query part")
	assert.Equal(t, "engine_1", part.PartID, "should update the PartID of the Part")
	assert.Equal(t, "engine", part.PartName, "should update the PartName of the Part")
	assert.Equal(t, "Two seater Private Plane", part.Description, "should update the Description of the Part")
	assert.Equal(t, uint32(10000), part.QuotePrice, "should update the QuotePrice of the Part")
	assert.Equal(t, uint32(9999), part.DealPrice, "should update the DealPrice of the Part")
	assert.True(t, part.IsUsed(), "should update the QuotePrice of the Part")
	assert.Equal(t,"",part.Owner,"Owner set to nil by default")

	// Part Does not exist
	mockStub.MockTransactionStart(txID)
	part, err = contract.SellPart(ctx, "properller_2", "", 69)
	mockStub.MockTransactionEnd(txID)
	assert.Nil(t, part, "should return nil part on Sell")
	assert.EqualError(t, err, "properller_2 does not exist", "should return error when Sell part fails")

	// Invalid PartID Case
	mockStub.MockTransactionStart(txID)
	part, err = contract.SellPart(ctx, "", "", 9999)
	mockStub.MockTransactionEnd(txID)
	assert.Nil(t, part, "should return nil part on Sell")
	assert.EqualError(t, err, "Invalid part ID", "should return error when Sell part fails")

}
