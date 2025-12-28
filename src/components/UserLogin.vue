<template>
    <div class="login-container" :style="{
        backgroundImage: `url(${require('/assets/jinhao_login.jpg')})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        height: '100vh'
    }">
        <form @submit.prevent="handleLogin" class="login-form">
            <h2>Login</h2>
            <div class="form-group">
                <label for="username">userName:</label>
                <input type="text" id="username" v-model="userName" required>
            </div>
            <button type="submit">Login</button>
            <div class="links">
                <router-link to="/signup">no account? sign up</router-link>
            </div>
        </form>
    </div>
</template>

<script>
import axios from 'axios'

export default {
    name: 'UserLogin',
    data() {
        return {
            userName: '',
            custId: '',
        }
    },
    methods: {
        async handleLogin() {
            try {
                const response = await axios.post('http://localhost:8088/user/login', {
                    userName: this.userName,
                    custId: this.custId,
                });

                if (response.data.success) {
                    localStorage.setItem('token', response.data.token);
                    localStorage.setItem('userId', response.data.userId);
                    localStorage.setItem('userName', response.data.userName);
                    localStorage.setItem('userRole', 'USER');

                    alert("successfully logged in");
                    this.$router.push('/userdash');
                }
            } catch (error) {
                alert('login failed, please check username and custId entry');
                console.error('Login error: ', error);
            }
        },
    }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.login-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

h2 {
  text-align: center;
  color: #333;
  margin-bottom: 2rem;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  color: #666;
}

input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

button {
  width: 100%;
  padding: 0.75rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  margin-top: 1rem;
}

button:hover {
  background-color: #45a049;
}

.error-message {
  color: #ff4444;
  margin-top: 0.5rem;
  text-align: center;
}

.links {
  margin-top: 1rem;
  text-align: center;
}

.links a {
  color: #4CAF50;
  text-decoration: none;
}

.links a:hover {
  text-decoration: underline;
}
</style>