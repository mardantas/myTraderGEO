/**
 * Vue Router Configuration
 */

import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores'

// ===== Route Definitions =====

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/login'
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/auth/LoginPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/signup',
    name: 'SignUp',
    component: () => import('@/views/auth/SignUpPage.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('@/views/dashboard/DashboardLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'DashboardHome',
        component: () => import('@/views/dashboard/DashboardHome.vue')
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/dashboard/ProfilePage.vue')
      },
      {
        path: 'profile/edit',
        name: 'EditProfile',
        component: () => import('@/views/dashboard/EditProfilePage.vue')
      }
    ]
  },
  {
    path: '/admin',
    name: 'Admin',
    component: () => import('@/views/admin/AdminPanel.vue'),
    meta: {
      requiresAuth: true,
      requiresRole: 'Moderator' // Moderator or Administrator
    }
  }
]

// ===== Create Router =====

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// ===== Navigation Guards =====

router.beforeEach((to, _from, next) => {
  const authStore = useAuthStore()

  // Check if route requires authentication
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)
  const requiresRole = to.matched.find((record) => record.meta.requiresRole)?.meta.requiresRole as
    | string
    | undefined

  // 1. Check authentication
  if (requiresAuth && !authStore.isAuthenticated) {
    // Redirect to login if not authenticated
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }

  // 2. Check role-based access
  if (requiresRole && authStore.currentUser) {
    const userRole = authStore.currentUser.role
    const hasAccess = checkRoleAccess(userRole, requiresRole)

    if (!hasAccess) {
      // Redirect to dashboard if user doesn't have required role
      console.warn(`Access denied: User role "${userRole}" does not have access to "${requiresRole}" route`)
      next({ name: 'Dashboard' })
      return
    }
  }

  // 3. Redirect authenticated users away from login
  if (!requiresAuth && authStore.isAuthenticated && to.name === 'Login') {
    next({ name: 'Dashboard' })
    return
  }

  // 4. Allow navigation
  next()
})

/**
 * Check if user role has access to required role
 * Role hierarchy: Administrator > Moderator > Trader
 */
function checkRoleAccess(userRole: string, requiredRole: string): boolean {
  const roleHierarchy: Record<string, number> = {
    Administrator: 3,
    Moderator: 2,
    Trader: 1
  }

  const userLevel = roleHierarchy[userRole] || 0
  const requiredLevel = roleHierarchy[requiredRole] || 0

  return userLevel >= requiredLevel
}

export default router
