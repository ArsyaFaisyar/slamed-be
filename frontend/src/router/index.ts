import { createRouter, createWebHistory, type RouteRecordRaw } from "vue-router";
import { menu } from "../constant/menu";
import { useAuthStore } from "../stores/auth";

const leaves = menu.flatMap((item) => {
  if (item.children) return item.children;

  return item.to ? [{ label: item.label, title: item.title, to: item.to }] : [];
});

const pages: RouteRecordRaw[] = leaves.map((leaf) => ({
  path: leaf.to,
  component: leaf.to === "/master/user" ? () => import("../views/UsersView.vue") : () => import("../views/PlaceholderView.vue"),
  meta: { title: leaf.title ?? leaf.label },
}));

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      component: () => import("../layouts/AppLayout.vue"),
      redirect: "/dashboard",
      meta: { requiresAuth: true },
      children: [
        ...pages,
        {
          path: "/profile",
          component: () => import("../views/ProfileView.vue"),
          meta: { title: "Profil" },
        },
      ],
    },
    {
      path: "/login",
      name: "login",
      component: () => import("../views/LoginView.vue"),
    },
  ],
});

router.beforeEach(async (to) => {
  const auth = useAuthStore();

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: "login" };
  }

  if (to.name === "login" && auth.isAuthenticated) {
    return "/dashboard";
  }

  if (auth.isAuthenticated && !auth.user) {
    try {
      await auth.fetchMe();
    } catch {
      if (!auth.isAuthenticated && to.meta.requiresAuth) {
        return { name: "login" };
      }
    }
  }
});

export default router;
