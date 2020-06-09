package parttracer

import(
	"testing"
	"github.com/stretchr/testify/assert"
)

func TestStateString(t *testing.T)  {
	assert.Equal(t, "NEW", NEW.String(), "should return string for new")
	assert.Equal(t, "USED", USED.String(), "should return string for used")
	assert.Equal(t, "REFURBISHED", REFURBISHED.String(), "should return string for refurbished")
	assert.Equal(t, "UNKNOWN", State(REFURBISHED+1).String(), "should return unknown when not one of constants")
}

func TestPartCondition(t *testing.T) {
	part:= Part{}
	part.Condition = USED

	assert.Equal(t, USED, part.GetCondition(),"should return used")
}

func TestSerialize(t *testing.T) {
	part := new(Part)
	part.PartID = "somepart"
	part.PartName = "someName"
	part.Description = "someDescription"
	part.QuotePrice = 1000
	part.Manufacturer = "someManufacturer"
	part.Owner = "someowner"
	part.DealPrice = 999
	part.EventTime = "time"
	part.Condition = USED


	bytes, err := part.Serialize()
	assert.Nil(t, err, "should not error on serialize")
	assert.Equal(t, `{"partId":"somepart","partName":"someName","description":"someDescription","quotePrice":1000,"manufacturer":"someManufacturer","owner":"someowner","dealPrice":999,"eventTime":"time","condition":2}`, string(bytes), "should return JSON formatted value")
}

func TestDeserialize(t *testing.T) {
	var cp *Part
	var err error

	goodJSON := `{"partId":"somepart","partName":"someName","description":"someDescription","quotePrice":1000,"manufacturer":"someManufacturer","owner":"someowner","dealPrice":999,"eventTime":"time","condition":2}`
	part:=new(Part)
	part.PartID = "somepart"
	part.PartName = "someName"
	part.Description = "someDescription"
	part.QuotePrice = 1000
	part.Manufacturer = "someManufacturer"
	part.Owner = "someowner"
	part.DealPrice = 999
	part.EventTime = "time"
	part.Condition = USED

	cp = new(Part)
	err = Deserialize([]byte(goodJSON), cp)

	assert.Nil(t, err, "should not return error for deserialize")
	assert.Equal(t, part, cp, "should create expected part")

	// Test for bad json

	badJSON := `{"partId":"somepart","partName":"someName","description":"someDescription","quotePrice":"NAN","manufacturer":"someManufacturer","owner":"someowner","dealPrice":999,"eventTime":"time","condition":2}`
	cp = new(Part)
	err = Deserialize([]byte(badJSON), cp)
	assert.EqualError(t, err, "Error deserializing part. json: cannot unmarshal string into Go struct field Part.quotePrice of type uint32", "should return error for bad data")
}
