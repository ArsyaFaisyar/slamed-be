import { getRequestPenawaranList } from "../api/requestPenawaran";
import { getLkh } from "../api/lkh";
import { getRkh } from "../api/rkh";

export async function getProjectIdsWithRequest(excludeRkhId?: number): Promise<Set<number>> {
  try {
    const [requests, lkhList, rkhList] = await Promise.all([getRequestPenawaranList(), getLkh(), getRkh()]);

    const lkhIdsWithRequest = new Set(requests.map((request) => request.lkh_id));
    const rkhIdsWithRequest = new Set(
      lkhList.filter((lkh) => lkhIdsWithRequest.has(lkh.id)).map((lkh) => lkh.rkh_id),
    );

    return new Set(
      rkhList
        .filter((rkh) => rkhIdsWithRequest.has(rkh.id) && rkh.id !== excludeRkhId)
        .map((rkh) => rkh.project_id),
    );
  } catch {
    return new Set();
  }
}