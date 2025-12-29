<template>
    <el-table :data="tableData" style="width:100%">
        <el-table-column prop="userId" label="userId" width="200" />
        <el-table-column prop="userName" label="userName" width="200" />
    </el-table>
</template>

<script>
import axios from 'axios'

export default {
    created: function () {
        this.fetchData();
    },

    data() {
        return {
            tableData: [],
        }
    },
    methods: {
        fetchData() {
            const token = localStorage.getItem('token');
            if (!token) {
                this.$router.push('/staff');
                return;
            }
            axios.get("http://localhost:8088/staff/findallcust", {
                params: {
                    staffId: localStorage.getItem('staffId')
                }
            }).then((response) => {
                console.log('Received data:', response.data);
                this.tableData = response.data;
            }).catch((error) => {
                console.error('Error fetching data:', error);
                if (error.response?.status === 401) {
                    localStorage.removeItem('token');
                    this.$router.push('/staff-login');
                }
            })
        },
    }
}
</script>

<style>
.el-button {
  margin: 0 5px;
}
</style>