<template>
    <el-tabs v-model="editableTabsValue" type="card" editable class="demo-tabs" @edit="handleTabsEdit">
        <el-tab-pane v-for="item in editableTabs" :key="item.name" :label="item.title" :name="item.name">
            <div class="chat-container">
                <div class="chat-main">
                    <div class="messages">
                        <div v-for="(msg, index) in item.messages" :key="index"
                            :class="['message', msg.sender === 'staff' ? 'message-right' : 'message-left']">
                            <div>{{ msg.content }}</div>
                            <div class="timestamp">{{ formatTime(msg.time) }}</div>
                        </div>
                    </div>

                    <div class="input-row">
                        <input v-model="item.newMessage" @keyup.enter="sendMessage(item.name)"
                            placeholder="please enter your message" class="chat-in" />
                        <button @click="sendMessage(item.name)" class="send-button">send</button>
                    </div>
                </div>


                <div class="chat-sidebar">
                    <div class="sidebar-content">
                        <p class="userId">userId: {{ item.customerId }}</p>
                        <p class="instruction-text">switch for manually close conversation:</p>
                        <p class="status-text">conversation status: {{ item.switch ? 'open' : 'close' }}</p>
                        <el-switch v-model="item.switch" class="ml-2" @change="handleSwitchChange(item)" :style="{
                            '--el-switch-on-color': item.switch ? '#13ce66' : '#aaa',
                            '--el-switch-off-color': '#ff4949'
                        }" />
                    </div>
                </div>
            </div>

        </el-tab-pane>
    </el-tabs>
</template>

<script>
import axios from 'axios';
import SockJS from 'sockjs-client';
import { Stomp } from '@stomp/stompjs';

export default {
    name: 'StaffChatPage',

    data() {
        return {
            staffInfo: '',
            textMessage: '',
            customerInfo: '',
            conversations: [],
            conversation: '',
            tabIndex: 0,
            editableTabsValue: '',
            editableTabs: [],
            customerTabMap: {},
            stomClient: null,
        }
    },
    async mounted() {
        if (!this.staffInfo) {
            this.fetchData();
        }

        const cachedTabs = localStorage.getItem('editableTabs');
        const cachedTabValue = localStorage.getItem('editableTabsValue');
        const cachedMap = localStorage.getItem('customerTabMap');

        if (cachedTabs && cachedTabValue) {
            this.editableTabs = JSON.parse(cachedTabs);
            this.editableTabsValue = cachedTabValue;
            this.customerTabMap = cachedMap ? JSON.parse(cachedMap) : {};
            this.tabIndex = this.editableTabs.length;
        }
    },
    methods: {
        async fetchData() {
            const token = localStorage.getItem('token');
            if (!token) {
                this.$router.push('/staff');
                return;
            }

            const cachedStaff = localStorage.getItem('staffInfo');
            if (cachedStaff) {
                this.staffInfo = JSON.parse(cachedStaff);
                this.initService(this.staffInfo.staffId);
                return;
            }

            axios.get("http://localhost:8088/staff/getStaffInfoById", {
                params: {
                    staffId: localStorage.getItem('staffId')
                }
            }).then((response) => {
                this.staffInfo = response.data;
                localStorage.setItem('staffInfo', JSON.stringify(this.staffInfo));
                this.initService(this.staffInfo.staffId);
                console.log('successfully received!');
            }).catch((error) => {
                console.error('Error fetching data:', error);
                if (error.response?.status === 401) {
                    localStorage.removeItem('token');
                    localStorage.removeItem('staffInfo');
                    this.$router.push('/login');
                }
            });
        },
        saveTabsToLocal() {
            localStorage.setItem('editableTabs', JSON.stringify(this.editableTabs));
            localStorage.setItem('editableTabsValue', this.editableTabsValue);
            localStorage.setItem('customerTabMap', JSON.stringify(this.customerTabMap));
        },

        initService(staffId) {
            this.stompClient = Stomp.over(() => new SockJS('http://localhost:8088/ws'));
            this.stompClient.connect({}, () => {
                this.stompClient.subscribe(`/cust_service/${staffId}/private`, message => {
                    const msg = JSON.parse(message.body);
                    this.handleIncomingMessage(msg);
                });
            }, err => console.error("WebSocket error:", err));
        },

        sendMessage(tabName) {
            const tab = this.editableTabs.find(t => t.name === tabName);
            const message = (tab?.newMessage || '').trim();
            if (!message) return;
            axios.get("http://localhost:8088/chat/get/conversationStatus", {
                params: { conversationId: tab.conversationId }
            }).then((response) => {
                const status = response.data;

                if (status === "CLOSED") {
                    tab.switch = false;
                    alert(`conversation ${tab.conversationId} ended`);
                    this.saveTabsToLocal();
                    return;
                }


                // === Only send if still active ===
                tab.messages.push({
                    content: message,
                    sender: 'staff',
                    time: new Date()
                });

                axios.post("http://localhost:8088/chat/insert/newMessages", {
                    senderId: Number(this.staffInfo.staffId),
                    receiverId: tab.customerId,
                    content: message,
                    conversationId: tab.conversationId
                });

                if (tab.customerId && this.stompClient?.connected) {
                    this.stompClient.send(
                        `/app/sendMsg`,
                        {},
                        JSON.stringify({
                            senderId: this.staffInfo.staffId,
                            receiverId: tab.customerId,
                            content: message,
                            sendDate: new Date(),
                            conversationId: tab.conversationId,
                        })
                    );
                }

                tab.newMessage = '';
                this.saveTabsToLocal();
            }).catch((error) => {
                console.error("There is an error:", error);
            });
        },


        formatTime(time) {
            let date = new Date(time);
            return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        },

        handleIncomingMessage(msg) {
            const conversationId = msg.conversationId;
            const customerId = msg.senderId;

            if (!this.customerTabMap[conversationId]) {
                const newTabName = `${++this.tabIndex}`;
                const newTab = {
                    title: `conversation ${msg.conversationId}`,
                    name: newTabName,
                    messages: [{ content: msg.content, sender: 'customer', time: new Date() }],
                    newMessage: '',
                    switch: true,
                    customerId: customerId,
                    conversationId: conversationId,
                };

                this.editableTabs.push(newTab);
                this.customerTabMap[conversationId] = newTabName;
                this.editableTabsValue = newTabName;
            } else {
                const tabName = this.customerTabMap[conversationId];
                const tab = this.editableTabs.find(t => t.name === tabName);
                if (tab) {
                    tab.messages.push({
                        content: msg.content,
                        sender: 'customer',
                        time: new Date()
                    });
                    this.editableTabsValue = tabName;
                }
            }

            this.saveTabsToLocal();
        },


        handleTabsEdit(targetName, action) {
            if (action === 'add') {
                const newTabName = `${++this.tabIndex}`;
                this.editableTabs.push({
                    title: `${this.staffInfo.staffName}'s new tab`,
                    name: newTabName,
                    messages: [],
                    newMessage: '',
                    switch: true,
                    conversationId: null,
                    customerId: null,
                });
                this.editableTabsValue = newTabName;
            } else if (action === 'remove') {
                let activeName = this.editableTabsValue;
                if (activeName === targetName) {
                    const tabs = this.editableTabs;
                    tabs.forEach((tab, index) => {
                        if (tab.name === targetName) {
                            if (tab.conversationId) {
                                delete this.customerTabMap[tab.conversationId];
                            }
                            const nextTab = tabs[index + 1] || tabs[index - 1];
                            if (nextTab) activeName = nextTab.name;
                        }
                    });
                }
                this.editableTabsValue = activeName;
                this.editableTabs = this.editableTabs.filter(tab => tab.name !== targetName);
            }
        },

        handleSwitchChange(tab) {
            if (tab.switch === true) {
                this.$message.warning("This conversation is already closed and cannot be reopened.");
                tab.switch = false;
                return;
            }


            axios.post("http://localhost:8088/chat/close/conversation",
                tab.conversationId,
                {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                }).then(() => {
                    console.log(`Conversation ${tab.conversationId} closed successfully.`);
                    tab.switch = false;
                }).catch((error) => {
                    console.error("Error closing conversation:", error);
                    this.$message.error("closing conversation failed, try again！");
                    tab.switch = true;
                });
        }
    }
}
</script>


<style>
/* Your existing styles remain the same */
.demo-tabs>.el-tabs__content {
    padding: 16px;
    font-size: 16px;
}

.chat-container {
    display: flex;
    flex-direction: row;
    height: 500px;
    border: 1px solid #ccc;
    padding: 12px;
    border-radius: 6px;
    gap: 12px;
}

.chat-main {
    flex: 1;
    display: flex;
    flex-direction: column;
}

.messages {
    flex-grow: 1;
    overflow-y: auto;
    margin-bottom: 10px;
    padding-bottom: 10px;
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.message {
    max-width: 60%;
    padding: 8px 12px;
    border-radius: 10px;
    word-break: break-word;
}

.message-left {
    background-color: #f1f1f1;
    align-self: flex-start;
    border-radius: 10px 10px 10px 0;
}

.message-right {
    background-color: #cce5ff;
    align-self: flex-end;
    border-radius: 10px 10px 0 10px;
}


.input-row {
    display: flex;
    gap: 8px;
}

.chat-in {
    flex: 1;
    padding: 8px;
    font-size: 14px;
}

.send-button {
    padding: 8px 16px;
    background-color: #409eff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.send-button:hover {
    background-color: #66b1ff;
}

.sidebar-info {
    display: flex;
    top: 10px;
    left: 10px;
}

.chat-sidebar {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 12px;
    min-width: 200px;
    border-left: 1px solid #eee;
}

.sidebar-content {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.timestamp {
    font-size: 12px;
    color: #aaa;
    margin-top: 4px;
}

.status-text {
    font-weight: bold;
    color: #333;
}

.instruction-text {
    font-size: 14px;
    color: #666;
}
</style>
