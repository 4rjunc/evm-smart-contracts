'use client'



const API_KEY = process.env.API_KEY

import React, { useEffect, useState } from 'react';
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

// Apollo Client setup
const client = new ApolloClient({
  uri: 'https://api.studio.thegraph.com/query/112718/counter/version/latest',
  cache: new InMemoryCache(),
  headers: {
    Authorization: `Bearer ${API_KEY}`
  }
});

// GraphQL query
const COUNTER_QUERY = gql`
  query GetCounterData {
    counterDecrements(first: 5) {
      id
      newValue
      caller
      blockNumber
    }
    counterIncrements(first: 5) {
      id
      newValue
      caller
      blockNumber
    }
  }
`;

export default function CounterSubgraphComponent() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const result = await client.query({
          query: COUNTER_QUERY,
          fetchPolicy: 'cache-first'
        });
        setData(result.data);
      } catch (err) {
        setError(err.message);
        console.error('Error fetching data:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  if (loading) return <div className="p-4">Loading...</div>;
  if (error) return <div className="p-4 text-red-500">Error occurred querying the Subgraph: {error}</div>;

  return (
    <main className="p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Counter Contract Data</h1>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Counter Decrements */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h2 className="text-lg font-semibold mb-3 text-red-600">Recent Decrements</h2>
          {data?.counterDecrements?.length > 0 ? (
            <div className="space-y-2">
              {data.counterDecrements.map((decrement) => (
                <div key={decrement.id} className="bg-white p-3 rounded border">
                  <div className="text-sm text-gray-600">ID: {decrement.id}</div>
                  <div className="font-medium">Value: {decrement.newValue}</div>
                  <div className="text-sm text-gray-600">Caller: {decrement.caller}</div>
                  <div className="text-sm text-gray-600">Block: {decrement.blockNumber}</div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-gray-500">No decrements found</div>
          )}
        </div>

        {/* Counter Increments */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <h2 className="text-lg font-semibold mb-3 text-green-600">Recent Increments</h2>
          {data?.counterIncrements?.length > 0 ? (
            <div className="space-y-2">
              {data.counterIncrements.map((increment) => (
                <div key={increment.id} className="bg-white p-3 rounded border">
                  <div className="text-sm text-gray-600">ID: {increment.id}</div>
                  <div className="font-medium">Value: {increment.newValue}</div>
                  <div className="text-sm text-gray-600">Caller: {increment.caller}</div>
                  <div className="text-sm text-gray-600">Block: {increment.blockNumber}</div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-gray-500">No increments found</div>
          )}
        </div>
      </div>

      {/* Raw JSON Data */}
      <div className="mt-6 bg-gray-100 p-4 rounded-lg">
        <h3 className="text-lg font-semibold mb-2">Raw Data</h3>
        <pre className="text-sm overflow-auto bg-white p-3 rounded border">
          {JSON.stringify(data, null, 2)}
        </pre>
      </div>

      {/* Refresh Button */}
      <div className="mt-4 text-center">
        <button
          onClick={() => window.location.reload()}
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
          Refresh Data
        </button>
      </div>
    </main>
  );
}

// Alternative version with Apollo Provider for apps that need it
export function CounterWithProvider() {
  return (
    <div>
      <CounterSubgraphComponent />
    </div>
  );
}
