while true; do
POD_NAME=$(kubectl get pods --field-selector=status.phase=Running -o custom-columns=':metadata.name' -n wxd | grep -E '^spark-master-.*$' | head -n 1)
if [ -z "$POD_NAME" ]; then
  echo "Error: No single running pod found matching the pattern."
else
  echo "Watching logs for pod: $POD_NAME"
  kubectl logs -f "$POD_NAME" -n wxd
  break
fi
  sleep 3
done