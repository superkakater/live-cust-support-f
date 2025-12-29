<template>
    <el-container class="layout-container" style="height: 100vh">
        <el-aside width="200px" style="background-color: #304156">
            <div style="height: 60px; display: flex; align-items: center; justify-content: center; color: white;">
                <h3>staff system</h3>
            </div>
            <el-menu active-text-color="#ffd04b" background-color="#304156" text-color="#fff"
                :default-active="$route.path" router>
                <el-menu-item index="/staffdash/table">
                    <el-icon>
                        <User />
                    </el-icon>
                    <span>customer management</span>
                </el-menu-item>

                <el-menu-item index="/staffdash/chat">
                    <el-icon>
                        <Service />
                    </el-icon>
                    <span>staff system</span>
                </el-menu-item>

                <el-menu-item index="/staffdash/history">
                    <el-icon>
                        <MessageBox />
                    </el-icon>
                    <span>会话记录</span>
                </el-menu-item>
            </el-menu>
        </el-aside>

        <el-container>
            <el-header
                style="background-color: #fff; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <el-breadcrumb separator="/">
                        <el-breadcrumb-item>staff system</el-breadcrumb-item>
                        <el-breadcrumb-item>{{ currentPageTitle }}</el-breadcrumb-item>
                    </el-breadcrumb>
                </div>
                <div>
                    <el-button type="danger" size="small" @click="logout" plain>
                        logout
                    </el-button>
                </div>
            </el-header>

            <el-main style="background-color: #f5f7fa; padding: 20px;">
                <div class="staffInfo">
                    <p>staffName: {{ information.staffName }}</p>
                    <p>staffId: {{ information.staffId }}</p>
                </div>
                <router-view></router-view>
            </el-main>
        </el-container>
    </el-container>
</template>

<script>
import { User, Service, MessageBox } from '@element-plus/icons-vue'
import axios from 'axios'
import { disconnectStompClient } from '@/websocket/wsConfig';

export default {
    components: { User, Service, MessageBox },
    computed: {
        currentPageTitle() {
            if (this.$route.path === '/staffdash/chat') {
                return 'staff service';
            } else if (this.$route.path === '/staffdash/table') {
                return 'staff management';
            } else {
                return 'chat history';
            }
        }
    },
    data: function () {
        return {
            information: '',
        }
    },
    mounted() {
        if (!this.information) {
            this.fetchData();
        }
    },
    methods: {
        fetchData() {
            const token = localStorage.getItem('token');
            if (!token) {
                this.$router.push('/staff-login');
                return;
            }

            axios.get("http://localhost:8088/staff/getStaffInfoById", {
                params: { staffId: localStorage.getItem('staffId') }
            }).then(res => {
                this.information = res.data;
            }).catch(err => {
                console.error(err);
                if (err.response?.status === 401) {
                    localStorage.removeItem('token');
                    this.$router.push('/staff-login');
                }
            });
        },

        logout() {
            localStorage.clear();
            this.closeService();
            this.$router.push('/staff');
            this.$message.success('already logged in');
        },
        closeService() {
            disconnectStompClient();
        },
    }
}
</script>

<style scoped>
.layout-container {
    min-width: 1200px;
}

.el-menu {
    border-right: none;
}

.el-header {
    padding: 0 20px;
}

.el-main {
    min-height: calc(100vh - 60px);
}
</style>