import PrenvsPanel from './components/PrenvsPanel.tsx';

const App = () => (
	<div className="dashboard">
		<header className="dashboard-header">
			<h1>prenv Dashboard</h1>
		</header>
		<main className="dashboard-main">
			<PrenvsPanel />
		</main>
	</div>
);

export default App;
