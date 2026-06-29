import EnvironmentsPanel from './components/EnvironmentsPanel.tsx';
import MessagesPanel from './components/MessagesPanel.tsx';

const App = () => (
	<div className="dashboard">
		<header className="dashboard-header">
			<h1>prenv Dashboard</h1>
		</header>
		<main className="dashboard-main">
			<EnvironmentsPanel />
			<MessagesPanel />
		</main>
	</div>
);

export default App;
