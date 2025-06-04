import {
  CounterDecrement as CounterDecrementEvent,
  CounterIncrement as CounterIncrementEvent,
  CounterReset as CounterResetEvent
} from "../generated/Counter/Counter"
import {
  CounterDecrement,
  CounterIncrement,
  CounterReset
} from "../generated/schema"

export function handleCounterDecrement(event: CounterDecrementEvent): void {
  let entity = new CounterDecrement(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newValue = event.params.newValue
  entity.caller = event.params.caller

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCounterIncrement(event: CounterIncrementEvent): void {
  let entity = new CounterIncrement(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newValue = event.params.newValue
  entity.caller = event.params.caller

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCounterReset(event: CounterResetEvent): void {
  let entity = new CounterReset(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.caller = event.params.caller

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
