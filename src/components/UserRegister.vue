<template>
    <div class="signup-container">
        <form @submit.prevent="handleSignup" class="signup-form">
            <h2>signup</h2>
            <div class="form-group">
                <label for="username">userName:</label>
                <input type="text" id="username" v-model="username" class="form-input" required>
            </div>
            <div class="form-group">
                <label for="serviceId">staffId:</label>
                <input type="text" id="serviceId" v-model="custId" class="form-input" required>
            </div>
            <div class="error-message" v-if="errorMessage">{{ errorMessage }}</div>
            <div class="button-group">
                <button type="submit" class="btn btn-primary">signup confirmation</button>
                <button type="button" class="btn btn-secondary" @click="goToLogin">return to login</button>
            </div>
        </form>
    </div>
</template>

<script>
import axios from 'axios'

export default {
    name: 'UserSignup',
    data() {
        return {
            username: '',
            custId: '',
            errorMessage: '',
        }
    },
    methods: {
        async handleSignup() {
            try {
                const response = await axios.post('http://localhost:8088/user/register', {
                    userName: this.username,
                    custId: parseInt(this.custId),
                })
                if (response.data === true) {
                    alert('signup success')
                    this.$router.push('/')
                } else {
                    this.errorMessage = 'userName has been taken'
                }
            } catch (error) {
                console.error('Signup error:', error.response?.data || error)
                this.errorMessage = error.response?.data || 'signup failed, please try again later'
            }
        },
        goToLogin() {
            this.$router.push('/')
        }
    }
}
</script>


<style scoped>
.signup-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
}

.signup-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.button-group {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.btn {
  width: 100%;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-primary {
  background-color: #4CAF50;
  color: white;
}

.btn-primary:hover {
  background-color: #45a049;
}

.btn-secondary {
  background-color: #f5f5f5;
  color: #333;
}

.btn-secondary:hover {
  background-color: #e8e8e8;
}

.error-message {
  color: #ff4444;
  margin-top: 0.5rem;
  text-align: center;
}
</style>