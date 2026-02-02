import { useReadContract } from 'wagmi';
import { CONTRACTS, PROJECT_REGISTRY_ABI } from '@/lib/contracts';

export function useProjects() {
  // Use getAllProjects which exists in the ABI
  const { data, isLoading, error } = useReadContract({
    address: CONTRACTS.ProjectRegistry,
    abi: PROJECT_REGISTRY_ABI,
    functionName: 'getAllProjects',
  });

  const projects = data as any[] | undefined;

  return {
    projects: projects || [],
    projectCount: projects?.length || 0,
    isLoading,
    error,
  };
}

export function useUserProjects(address: `0x${string}` | undefined) {
  // Get all projects and filter client-side for now
  const { projects, isLoading } = useProjects();

  const userProjects = address 
    ? projects.filter((p: any) => p.owner?.toLowerCase() === address.toLowerCase())
    : [];

  return {
    projects: userProjects,
    isLoading,
  };
}
