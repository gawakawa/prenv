import { useEffect, useState } from 'react';

type Message = { id: number; body: string };

const App = () => {
	const [count, setCount] = useState(0);
	const [messages, setMessages] = useState<Message[]>([]);

	useEffect(() => {
		fetch('/api/messages')
			.then((r) => r.json())
			.then(setMessages)
			.catch(console.error);
	}, []);

	return (
		<div>
			<h1>vite-frontend</h1>
			<button type="button" onClick={() => setCount((c) => c + 1)}>
				count: {count}
			</button>
			<ul>
				{messages.map((m) => (
					<li key={m.id}>{m.body}</li>
				))}
			</ul>
		</div>
	);
};

export default App;
