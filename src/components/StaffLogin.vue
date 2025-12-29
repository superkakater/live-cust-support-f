<template>
    <div class="login-container">
        <h2>StaffLogin</h2>
        <form @submit.prevent="handleLogin" class="login-form">
            <div class="form-group">
                <label for="staffName">staffName</label>
                <input type="text" id="staffName" v-model="staffName" required placeholder="please enter staff's name">
            </div>
            <div class="button-group">
                <button type="submit" class="submit-btn">Login</button>
            </div>
            <div class="links">
                <router-link to="/staffSignup">no account? sign up</router-link>
            </div>
        </form>
    </div>
</template>

<script>
import axios from 'axios'

export default {
    name: 'StaffLogin',
    data() {
        return {
            staffName: '',
            password: '',
        }
    },
    methods: {
        async handleLogin() {
            try {
                const response = await axios.post('http://localhost:8088/staff/login', {
                    staffName: this.staffName
                });

                if (response.data.success) {
                    localStorage.setItem('token', response.data.token);
                    localStorage.setItem('staffId', response.data.staffId);
                    localStorage.setItem('staffName', response.data.staffName);
                    localStorage.setItem('userRole', 'STAFF');

                    alert("successfully login");
                    this.$router.push('/staffdash/table');
                }
            } catch (error) {
                alert('login failed, please check staffName enter');
                console.error('Login error: ', error);
            }
        },
    }
}
</script>

<style scoped>
.login-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  background-color: #f5f5f5;
}

.login-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

.links {
  margin-top: 1rem;
  text-align: center;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
}

input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.button-group {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1rem;
}

.submit-btn {
  padding: 0.75rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}

.submit-btn:hover {
  background-color: #45a049;
}

.link-btn {
  background: none;
  border: none;
  color: #4CAF50;
  cursor: pointer;
  text-decoration: underline;
}

.link-btn:hover {
  color: #45a049;
}
</style>