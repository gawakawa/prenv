import { useState } from 'react';

const App = () => {
	const [count, setCount] = useState(0);

	return (
		<div>
			<h1>vite-frontend</h1>
			<button type="button" onClick={() => setCount((c) => c + 1)}>
				count: {count}
			</button>
		</div>
	);
};

export default App;
