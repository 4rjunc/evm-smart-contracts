import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { CounterDecrement } from "../generated/schema"
import { CounterDecrement as CounterDecrementEvent } from "../generated/Counter/Counter"
import { handleCounterDecrement } from "../src/counter"
import { createCounterDecrementEvent } from "./counter-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let newValue = BigInt.fromI32(234)
    let caller = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newCounterDecrementEvent = createCounterDecrementEvent(newValue, caller)
    handleCounterDecrement(newCounterDecrementEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("CounterDecrement created and stored", () => {
    assert.entityCount("CounterDecrement", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "CounterDecrement",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "newValue",
      "234"
    )
    assert.fieldEquals(
      "CounterDecrement",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "caller",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
