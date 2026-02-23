import { cn } from "@/lib/utils";

interface LoadingSkeletonProps {
  className?: string;
  count?: number;
}

export function LoadingSkeleton({
  className,
  count = 1,
}: LoadingSkeletonProps) {
  return (
    <>
      {Array.from({ length: count }, (_, i) => (
        <div
          key={i}
          className={cn(
            "animate-pulse rounded-lg bg-neutral-800/50",
            className ?? "h-20 w-full",
          )}
        />
      ))}
    </>
  );
}
