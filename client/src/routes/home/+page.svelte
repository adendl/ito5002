<script lang="ts">

    // On mount and authentication handling
    import { onMount } from "svelte";
    let loaded = false;

    onMount(() => {
    });


    function handleLogin() {
        window.location.href = '/login'; // Function to handle the login redirection
    }
</script>

<div class="home-container">
    <div class="app-bar">
        <div class="logo" on:click={() => window.location.href = '/'}>Community<i class="fa-solid fa-bolt"></i>Power</div>
        <button class="login-btn" on:click={handleLogin}>Login</button>
    </div>
    
    <section class="hero">
        <h1>Welcome to Community Power</h1>
        <p>Your one-stop platform for EV charging solutions.</p>
    </section>
    
    <div class="services-section">
        <div class="card">
            <h3>For Consumers</h3>
            <p>Explore our intuitive map to find and book charging stations easily. Our platform allows you to access real-time information on the availability of charging points, facilitating convenient scheduling.</p>
            <p>With our user-friendly interface, you can plan your charges according to your daily schedule, ensuring your vehicle is always ready to go. Our system supports various payment methods and provides detailed receipts for each transaction, simplifying your charging experience.</p>
        </div>
        <div class="card">
            <h3>For Suppliers</h3>
            <p>Join our network to boost the visibility of your charging stations. Our platform provides suppliers with powerful tools to manage their listings, track usage, and optimize booking processes.</p>
            <p>We offer detailed analytics to help you understand customer usage patterns and adjust your operations accordingly. This helps in maximizing station utilization and increasing revenue. Our support team is always on hand to ensure smooth integration and operation.</p>
        </div>
        <div class="card">
            <h3>Eco-Friendly Solutions</h3>
            <p>At Community Power, we are committed to promoting sustainable energy solutions. Our charging stations primarily use renewable energy sources, reducing the carbon footprint associated with electric vehicle charging.</p>
            <p>We also participate in various green initiatives and partner with other eco-conscious organizations to foster a sustainable future. Learn more about our efforts to support environmental sustainability and how you can contribute to making a difference with every charge.</p>
        </div>
    </div>

    <footer class="footer">
        <p>&copy; 2024 Community Power. All rights reserved.</p>
    </footer>
</div>

<style>
    /* Additional styling can be defined here */
    .home-container {
        display: flex;
        flex-direction: column;
        height: 100vh;
    }

    .header {
        background-color: #282c34;
        color: white;
        display: flex;
        justify-content: space-between;
        padding: 20px 40px;
    }

    .hero {
        background-color: #432874;
        color: white;
        padding: 40px 20px;
        text-align: center;
    }

    .services-section {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 20px;
        padding: 20px;
        background-color: #340e36;
    }

    .card {
        background: #220131;
        color: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.3);
        transition: transform 0.3s ease;
    }

    .card:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 20px rgba(0,0,0,0.5);
    }

    .footer {
        background-color: #282c34;
        color: white;
        text-align: center;
        padding: 20px;
        margin-top: auto; /* pushes the footer to the bottom of the layout */
    }

    .app-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px 20px;
        background-color: #282c34;
        color: white;
    }

    .logo {
        font-weight: bold;
        cursor: pointer;
    }

    .login-btn {
        padding: 8px 16px;
        background-color: #007bff;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
    }

    .login-btn:hover {
        background-color: #0056b3;
    }
</style>