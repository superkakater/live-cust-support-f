import { createRouter, createWebHistory } from 'vue-router'
import UserLogin from '@/components/UserLogin.vue'
import StaffLogin from '@/components/StaffLogin.vue'
import UserRegister from '@/components/UserRegister.vue'
import StaffRegister from '@/components/StaffRegister.vue'
import UserDash from '@/components/dashboards/UserDash.vue'
import StaffDash from '@/components/dashboards/StaffDash.vue'
import SelectPage from '@/components/SelectPage.vue'
import StaffChatPage from '@/components/dashboards/StaffChatPage.vue'
import ConversationList from '@/components/dashboards/ConversationList.vue'
import StaffLayout from '@/components/dashboards/StaffLayout.vue'

const routes = [
    {
        path: '/',
        name: 'Select',
        component: SelectPage
    },
    {
        path: '/staff',
        name: 'StaffLogin',
        component: StaffLogin
    },
    {
        path: '/staffSignup',
        name: 'StaffSignup',
        component: StaffRegister
    },
    {
        path: '/userSignup',
        name: 'UserSignup',
        component: UserRegister
    },
    {
        path: '/user',
        name: 'UserLogin',
        component: UserLogin
    },
    {
        path: '/staffdash',
        component: StaffLayout,
        children: [
            { path: 'info', component: StaffDash },
            { path: 'chat', component: StaffChatPage },
            { path: 'history', component: ConversationList },
        ]
    },
    {
        path: '/userdash',
        name: 'UserChatPage',
        component: UserDash
    }
]

const router = createRouter({
    history: createWebHistory(process.env.BASE_URL),
    routes
})

router.beforeEach((to, from, next) => {
    const isAuthenticated = localStorage.getItem('token')

    if (to.matched.some(record => record.meta.requiresAuth)) {
        if (!isAuthenticated) {
            next({ name: 'Selection' })
        } else {
            next()
        }
    } else {
        next()
    }
})

export default router