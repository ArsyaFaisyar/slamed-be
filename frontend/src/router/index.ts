import { createRouter, createWebHistory, type RouteRecordRaw } from "vue-router";
import { menu } from "../constant/menu";

const leaves = menu.flatMap((item) => {
  if (item.children) return item.children;
  return item.to ? [{ label: item.label, title: item.title, to: item.to }] : [];
});

const pages: RouteRecordRaw[] = leaves.map((leaf) => ({
  path: leaf.to,
  component: () => import("../views/PlaceholderView.vue"),
  meta: { title: leaf.title ?? leaf.label },
}));

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      component: () => import("../layouts/AppLayout.vue"),
      redirect: "/dashboard",
      children: pages,
    },
    {
      path: "/login",
      name: "login",
      component: () => import("../views/LoginView.vue"),
    },
  ],
});

export default router;
