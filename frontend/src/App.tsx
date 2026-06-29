import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';

type Message = { id: number; body: string };

const fetchMessages = async (): Promise<Message[]> => {
	const r = await fetch('/api/messages');
	if (!r.ok) {
		throw new Error(`Failed to fetch messages: ${r.status}`);
	}
	return r.json();
};

const App = () => {
	const [count, setCount] = useState(0);
	const {
		data: messages,
		isPending,
		isError,
		error,
	} = useQuery({
		queryKey: ['messages'],
		queryFn: fetchMessages,
	});

	return (
		<div>
			<h1>vite-frontend</h1>
			<button type="button" onClick={() => setCount((c) => c + 1)}>
				count: {count}
			</button>
			{isPending ? (
				<p>Loading...</p>
			) : isError ? (
				<p>Error: {error.message}</p>
			) : (
				<ul>
					{messages.map((m) => (
						<li key={m.id}>{m.body}</li>
					))}
				</ul>
			)}
		</div>
	);
};

export default App;
