import { createRouter, createWebHistory, type RouteRecordRaw } from "vue-router";
import { menu } from "../constant/menu";
import { useAuthStore } from "../stores/auth";
import { canAccessRoute } from "../constant/permissions";

const leaves = menu.flatMap((item) => {
  if (item.children) return item.children;

  return item.to ? [{ label: item.label, title: item.title, to: item.to }] : [];
});

const viewLoaders: Record<string, () => Promise<unknown>> = {
  "/master/user": () => import("../views/UsersView.vue"),
  "/master/branch": () => import("../views/BranchesView.vue"),
  "/master/media-pengadaan": () => import("../views/MediaPengadaanView.vue"),
  "/master/area": () => import("../views/AreaView.vue"),
  "/transaksi/customer": () => import("../views/CustomersView.vue"),
  "/transaksi/project": () => import("../views/ProjectsView.vue"),
  "/master/kategori-customer": () => import("../views/CustomerCategoriesView.vue"),
  "/master/status-project": () => import("../views/ProjectStatusesView.vue"),
  "/aktivitas/rkh": () => import("../views/RkhView.vue"),
  "/aktivitas/lkh": () => import("../views/LkhView.vue"),
  "/support/request-penawaran": () => import("../views/RequestPenawaranListView.vue"),
  "/transaksi/customer-approval": () => import("../views/CustomerApprovalView.vue"),
  "/setting/template-penawaran": () => import("../views/TemplatePenawaranView.vue"),
};

const pages: RouteRecordRaw[] = leaves.map((leaf) => ({
  path: leaf.to,
  component: viewLoaders[leaf.to] ?? (() => import("../views/PlaceholderView.vue")),
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
        {
          path: "/master/branch/:id",
          component: () => import("../views/BranchDetailView.vue"),
          meta: { title: "Detail Cabang" },
        },
        {
          path: "/aktivitas/lkh/:rkhId",
          component: () => import("../views/LkhFormView.vue"),
          meta: { title: "Form LKH" },
        },
        { path: "/aktivitas/lkh/:lkhId/request-penawaran", component: () => import("../views/RequestPenawaranView.vue"), meta: { requiresAuth: true } },
        { path: "/aktivitas/request-penawaran/:requestId", component: () => import("../views/RequestPenawaranDetailView.vue"), meta: { requiresAuth: true } },
        {
          path: "/transaksi/project/:projectId",
          component: () => import("../views/ProjectDetailView.vue"),
          meta: { title: "Detail Project" },
        },
        {
          path: "/setting/template-penawaran/baru",
          component: () => import("../views/TemplatePenawaranFormView.vue"),
          meta: { title: "Template Baru" },
        },
        {
          path: "/setting/template-penawaran/:id",
          component: () => import("../views/TemplatePenawaranFormView.vue"),
          meta: { title: "Edit Template" },
        },
        { path: "/aktivitas/request-penawaran/:requestId/revisi/:revisiId", component: () => import("../views/RevisiPenawaranView.vue"), meta: { requiresAuth: true } },
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
      auth.logout();
      return { name: "login" };
    }
  }

  if (to.meta.requiresAuth && auth.user) {
    const role = auth.user.role;

    if (typeof role !== "string" || !canAccessRoute(to.path, role)) {
      return "/dashboard";
    }
  }

  // 5. Izinkan navigasi
  return true;
});

export default router;
