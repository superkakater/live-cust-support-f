<template>
  <div>
    <el-table :data="tableData" style="width: 100%">
      <el-table-column prop="conversationId" label="conversationId" width="120" />
      <el-table-column prop="customerId" label="userId" width="120" />
      <el-table-column prop="staffId" label="staffId" width="120" />
      <el-table-column prop="creDate" label="date&time" width="600" />
      <el-table-column prop="status" label="conversation_status" width="120" />
      <el-table-column fixed="right" label="Operations" min-width="120">
        <template #default="{ row }">
          <el-button link type="primary" size="small" @click="handleClick(row)">
            Detail
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog
      v-model="dialogVisible"
      title="conversation details"
      width="40%"
      :close-on-click-modal="true"
      center
    >
      <p><strong>conversationId:</strong> {{ selectedRow?.conversationId }}</p>
      <p><strong>userId:</strong> {{ selectedRow?.customerId }}</p>
      <p><strong>staffId:</strong> {{ selectedRow?.staffId }}</p>
      <p><strong>date&time:</strong> {{ selectedRow?.creDate }}</p>
      <p><strong>conversation_status:</strong> {{ selectedRow?.status }}</p>
      <el-divider />
      <p><strong>conversation recorrds:</strong></p>
      <pre style="white-space: pre-wrap;">{{ conversationHistory }}</pre>
    </el-dialog>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      tableData: [],
      dialogVisible: false,
      selectedRow: null,
      conversationHistory: '', 
    }
  },

  created() {
    this.fetchData()
  },

  methods: {
    fetchData() {
      const token = localStorage.getItem('token')
      if (!token) {
        this.$router.push('/staff-login')
        return
      }

      axios.get("http://localhost:8088/chat/get/ConversationListByStaffId", {
        params: {
          staffId: localStorage.getItem('staffId')
        }
      }).then((response) => {
        console.log('Received data:', response.data)
        this.tableData = response.data
      }).catch((error) => {
        console.error('Error fetching data:', error)
        if (error.response?.status === 401) {
          localStorage.removeItem('token')
          this.$router.push('/staff-login')
        }
      })
    },

    handleClick(row) {
      this.selectedRow = row
      this.dialogVisible = true
      this.conversationHistory = 'loading...'

      axios.get("http://localhost:8088/chat/get/conversationHistory", {
        params: {
          conversationId: row.conversationId
        }
      }).then((response) => {
        this.conversationHistory = response.data
      }).catch((error) => {
        console.error('Error loading conversation history:', error)
        this.conversationHistory = 'cannot load conversation details'
      })
    },
  },
}
</script>