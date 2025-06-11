import Image from "next/image";
import CounterSubgraphComponent from './CounterSubgraphComponent';
import { ChartComponent } from "./Graph";


const data = [
  { value: 0, time: 1642425322 },            // Base time
  { value: 8, time: 1642425622 },            // +5 mins
  { value: 10, time: 1642425922 },           // +5 mins
  { value: 20, time: 1642426222 },           // +5 mins
  { value: 3, time: 1642426522 },            // +5 mins
  { value: 43, time: 1642427022 },           // +8 mins
  { value: 41, time: 1642427322 },           // +5 mins
  { value: 43, time: 1642427622 },           // +5 mins
  { value: 56, time: 1642427922 },           // +5 mins
  { value: 46, time: 1642428222 }            // +5 mins
];

export default function Home() {
  return (
    <div className="">
      <main className="">
        <CounterSubgraphComponent />

        <div className="mt-10">
          <ChartComponent data={data}></ChartComponent>

        </div>
      </main>
    </div>
  );
}
