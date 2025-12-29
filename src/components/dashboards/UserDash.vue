<template>
    <div class="logout-button">
        <el-button type="danger" size="small" plain @click="logout">
            Logout
        </el-button>
    </div>

    <div class="userInfo">
        <p>userName: {{ userInfo.userName }}</p>
        <p>userId: {{ userInfo.userId }}</p>
        <p>your cust-serviceId: {{ userInfo.custId }}</p>
    </div>

    <div class="customer-service">
        <div class="service-container">
            <div class="button-container">
                <div class="service-button human-button" @click="toggleService()">
                    <span>{{ humanOpen ? '×' : 'service' }}</span>
                </div>
            </div>

            <div class="dialog-container">
                <div class="chat-dialog" v-if="humanOpen">
                    <div class="chat-header">
                        <h3>human customer-service</h3>
                        <span class="close-btn" @click="closeService()">×</span>
                    </div>

                    <div class="chat-content" ref="humanChatContent">
                        <div v-for="(message, index) in humanMessages" :key="'human-' + index"
                            :class="['message', message.sender]">
                            <div class="message-content">{{ message.content }}</div>
                            <div class="message-time">{{ formatTime(message.time) }}</div>
                        </div>
                    </div>

                    <div class="chat-input">
                        <input v-model="humanMessage" @keyup.enter="sendHumanMessage"
                            placeholder="please describe the problems you have..." :disabled="connecting" />
                        <button @click="sendHumanMessage" :disabled="connecting">
                            {{ connecting ? 'connecting...' : 'send' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';
import SockJS from 'sockjs-client';
import { Stomp } from '@stomp/stompjs';
let stompClient

export default {
    name: 'SimpleCustomerService',

    data() {
        return {
            humanOpen: false,
            humanMessage: '',
            connecting: false,
            humanMessages: [],
            userInfo: {},

            conversationId: -1,        // ✅ consistent name
            connectionActive: false,
            creDate: '',
        };
    },

    async mounted() {
        await this.fetchData();
    },

    methods: {
        fetchData() {
            const token = localStorage.getItem('token');
            if (!token) {
                this.$router.push('/');
                return;
            }

            const userId = localStorage.getItem('userId');
            const cacheKey = `${userId}_userInfo`;

            const cachedUser = localStorage.getItem(cacheKey);
            if (cachedUser) {
                this.userInfo = JSON.parse(cachedUser);
                return;
            }

            axios.get("http://localhost:8088/user/getUserInfoById", {
                params: { userId }
            }).then((response) => {
                this.userInfo = response.data;
                this.creDate = new Intl.DateTimeFormat('zh-CN', {
                    year: 'numeric', month: '2-digit', day: '2-digit',
                }).format(new Date(this.userInfo.creDate));

                localStorage.setItem(cacheKey, JSON.stringify(this.userInfo));
            }).catch((error) => {
                console.error('Error fetching data:', error);
                if (error.response?.status === 401) {
                    localStorage.removeItem('token');
                    this.$router.push('/');
                }
            });
        },

        logout() {
            localStorage.clear();
            this.$router.push('/');
            this.$message.success('already logged out')
        },
        toggleService() {
            this.humanOpen = !this.humanOpen;
            if (this.humanOpen) {
                this.$nextTick(() => {
                    this.initHumanService();
                });
            }
        },

        closeService() {
            this.humanOpen = false;
            this.humanOpen = false;

            if (this.humanSub) {
                this.humanSub.unsubscribe();
                this.humanSub = null;
            }

            if (stompClient && stompClient.connected) {
                stompClient.disconnect(() => {
                    this.connectionActive = false;
                });
            }

            if (this.conversationId && this.conversationId !== -1) {
                axios.post("http://localhost:8088/chat/close/conversation", this.conversationId, {
                    headers: { 'Content-Type': 'application/json' }
                }).catch(err => console.error("close conversation failed:", err));
            }
        },

        async startConversation() {
            try {
                await axios.post("http://localhost:8088/chat/conversation/start", {
                    userId: this.userInfo.userId,
                    staffId: this.userInfo.custId
                });

                const response = await axios.get("http://localhost:8088/chat/userId/getConversationId", {
                    params: { userId: this.userInfo.userId }
                });
                this.conversationId = response.data;
            } catch (error) {
                console.error("Error in starting conversation:", error);
            }
        },
        async initHumanService() {
            if (this.connectionActive) return;

            stompClient = Stomp.over(() => new SockJS('http://localhost:8088/ws'));
            stompClient.reconnect_delay = 5000;

            this.connecting = true;
            this.humanMessages.push({
                sender: 'server',
                content: 'trying to reach the cust-service staff, please wait...',
                time: new Date()
            });
            this.scrollToBottom('human');

            stompClient.connect({}, async () => {
                this.connectionActive = true;



                await axios.post("http://localhost:8088/chat/userid/close/conversation", this.userInfo.userId, {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                await this.startConversation();

                this.humanSub = stompClient.subscribe(`/cust_service/${this.userInfo.userId}/private`, (message) => {
                    if (!this.humanOpen) return; // dialog closed => no ref

                    const msg = JSON.parse(message.body);
                    this.humanMessages.push({
                        sender: 'server',
                        content: msg.content,
                        time: new Date()
                    });
                    this.scrollToBottom('human');
                });


                this.humanMessages.push({
                    sender: 'server',
                    content: `hello ${this.userInfo.userId}, customer service is at your service, how may we help you?`,
                    time: new Date()
                });

                this.connecting = false;            // ✅ only enable after startConversation done
                this.scrollToBottom('human');

            }, (error) => {
                console.error("WebSocket connection error:", error);
                this.connecting = false;
                this.connectionActive = false;
            });
        },

        killService() {
            if (stompClient && stompClient.connected) {
                stompClient.disconnect(() => {
                    console.log("old WebSocket is disconnected");
                    this.connectionActive = false;


                    this.humanMessages.push({
                        sender: 'server',
                        content: 'conversation is ended, starting to reconnect to human service...',
                        time: new Date()
                    });
                    this.scrollToBottom('human');

                    setTimeout(() => {
                        this.initHumanService();
                    }, 500);
                });
            } else {
                console.log("WebSocket is disconnected, reconnects directly");
                this.connectionActive = false;

                this.humanMessages.push({
                    sender: 'server',
                    content: 'conversation is outdated, trying to reconnect...',
                    time: new Date()
                });
                this.scrollToBottom('human');

                setTimeout(() => {
                    this.initHumanService();
                }, 500);
            }
        },
        sendHumanMessage() {
            if (!this.conversationId || this.conversationId === -1) {
                console.error("conversationId not ready yet");
                return;
            }
            axios.get("http://localhost:8088/chat/get/conversationStatus", {
                params: {
                    conversationId: this.conversationId
                }
            }).then((response) => {
                const status = response.data;
                console.log("Status:", status);

                if (status === "CLOSED") {
                    this.killService();
                    return;
                } else {
                    console.log("still active");
                    if (!stompClient || !stompClient.connected) {
                        console.error("Not connected to WebSocket");
                        return;
                    }

                    if (!this.humanMessage) {
                        console.error("Nothing is entered");
                        return;
                    }

                    this.humanMessages.push({
                        sender: 'client',
                        content: this.humanMessage,
                        time: new Date()
                    })

                    let msg = this.humanMessage;
                    this.humanMessage = ''
                    this.scrollToBottom('human')

                    const thisMessage = {
                        senderId: Number(this.userInfo.userId),
                        receiverId: Number(this.userInfo.custId),
                        content: msg,
                        sendDate: new Date(),
                        conversationId: this.conversationId
                    }

                    axios.post("http://localhost:8088/chat/insert/newMessages", {
                        senderId: Number(this.userInfo.userId),
                        receiverId: Number(this.userInfo.custId),
                        content: msg,
                        conversationId: this.conversationId
                    });

                    stompClient.send("/app/sendMsg", {}, JSON.stringify(thisMessage));
                }

            }).catch((error) => {
                console.error("There is an error:", error);
            });

        },

        scrollToBottom(type) {
            this.$nextTick(() => {
                const refName = type === 'ai' ? 'aiChatContent' : 'humanChatContent';
                const el = this.$refs[refName];

                // ref can be null if v-if is false or component unmounted
                if (!el) return;

                el.scrollTop = el.scrollHeight;
            });
        },





        formatTime(time) {
            return time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }
    }
}

</script>

<style scoped>
.logout-button {
    position: fixed;
    right: 20px;
    top: 20px;
}

.userInfo {
    position: fixed;
    left: 20px;
    top: 80px;
    padding: 10px 20px;
    background-color: #f9f9f9;
    border-radius: 8px;
    box-shadow: 0 0 8px rgba(0, 0, 0, 0.08);
    line-height: 1.8;
}

.customer-service {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 1000;
    max-width: 100%;
}

.service-container {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.button-container {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.service-button {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
    font-size: 16px;
    font-weight: bold;
    color: white;
    user-select: none;
    transition: transform 0.2s;
}

.service-button:hover {
    transform: scale(1.05);
}

.iframe-container {
    margin-left: 350px;
    margin-top: 100px;
    /* adjust so iframe starts below userInfo */
    padding-left: 20px;
    /* optional, align with userInfo */
}

.ai-button {
    background-color: #67C23A;
}

.human-button {
    background-color: #409EFF;
}

.chat-dialog {
    width: 400px;
    height: 600px;
    display: flex;
    flex-direction: column;
    background-color: white;
    border-radius: 8px;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
    overflow: hidden;
}

.chat-header {
    padding: 15px;
    background-color: #409EFF;
    color: white;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.chat-header h3 {
    margin: 0;
    font-size: 16px;
}

.close-btn {
    font-size: 20px;
    cursor: pointer;
    padding: 0 10px;
}

.chat-content {
    flex: 1;
    overflow-y: auto;
    padding: 15px;
    background-color: whitesmoke;
    display: flex;
    flex-direction: column;
    gap: 12px;
}


.message {
    display: flex;
    flex-direction: column;
    max-width: 80%;
}

.message.client {
    align-self: flex-end;
    text-align: right;
}

.message.server {
    align-self: flex-start;
    text-align: left;
}

.message-content {
    display: inline-block;
    padding: 10px 14px;
    border-radius: 16px;
    font-size: 14px;
    word-break: break-word;
    line-height: 1.5;
}

.message.client .message-content {
    background-color: #409EFF;
    color: white;
    border-bottom-right-radius: 2px;
}

.message.server .message-content {
    background-color: #ffffff;
    border: 1px solid #ddd;
    color: #333;
    border-bottom-left-radius: 2px;
}

.message-time {
    font-size: 12px;
    color: #aaa;
    margin-top: 4px;
}

.chat-input {
    display: flex;
    padding: 10px;
    border-top: 1px solid #eee;
    background-color: #fff;
}

.chat-input input {
    flex: 1;
    height: 40px;
    padding: 8px 10px;
    font-size: 14px;
    border-radius: 6px;
    border: 1px solid #ccc;
    margin-right: 10px;
    box-sizing: border-box;
}

.chat-input button {
    width: 80px;
    height: 40px;
    background-color: #409EFF;
    border: none;
    border-radius: 6px;
    color: #fff;
    font-size: 14px;
    cursor: pointer;
}

.chat-input button:disabled {
    background-color: #66b1ff;
}
</style>
