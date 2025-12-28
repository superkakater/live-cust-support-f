<template>
  <div class="role-container">
    <h1 class="title">Select Your Role</h1>

    <div class="button-group">
      <button class="role-btn customer" @click="goUser">
        Customer
      </button>

      <button class="role-btn staff" @click="goStaff">
        Staff
      </button>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const goUser = () => {
  router.push('/user')
}

const goStaff = () => {
  router.push('/staff')
}
</script>

<style scoped>
.role-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: #f7f9fc;
}

.title {
  margin-bottom: 2rem;
  font-size: 2rem;
  font-weight: 600;
  color: #333;
}

.button-group {
  display: flex;
  gap: 1.5rem;
}

.role-btn {
  padding: 1rem 2.5rem;
  font-size: 1.1rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.role-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
}

.customer {
  background-color: #4f46e5;
  color: white;
}

.staff {
  background-color: #059669;
  color: white;
}
</style>
