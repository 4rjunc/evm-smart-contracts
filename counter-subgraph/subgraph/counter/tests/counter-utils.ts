import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  CounterDecrement,
  CounterIncrement,
  CounterReset
} from "../generated/Counter/Counter"

export function createCounterDecrementEvent(
  newValue: BigInt,
  caller: Address
): CounterDecrement {
  let counterDecrementEvent = changetype<CounterDecrement>(newMockEvent())

  counterDecrementEvent.parameters = new Array()

  counterDecrementEvent.parameters.push(
    new ethereum.EventParam(
      "newValue",
      ethereum.Value.fromUnsignedBigInt(newValue)
    )
  )
  counterDecrementEvent.parameters.push(
    new ethereum.EventParam("caller", ethereum.Value.fromAddress(caller))
  )

  return counterDecrementEvent
}

export function createCounterIncrementEvent(
  newValue: BigInt,
  caller: Address
): CounterIncrement {
  let counterIncrementEvent = changetype<CounterIncrement>(newMockEvent())

  counterIncrementEvent.parameters = new Array()

  counterIncrementEvent.parameters.push(
    new ethereum.EventParam(
      "newValue",
      ethereum.Value.fromUnsignedBigInt(newValue)
    )
  )
  counterIncrementEvent.parameters.push(
    new ethereum.EventParam("caller", ethereum.Value.fromAddress(caller))
  )

  return counterIncrementEvent
}

export function createCounterResetEvent(caller: Address): CounterReset {
  let counterResetEvent = changetype<CounterReset>(newMockEvent())

  counterResetEvent.parameters = new Array()

  counterResetEvent.parameters.push(
    new ethereum.EventParam("caller", ethereum.Value.fromAddress(caller))
  )

  return counterResetEvent
}
