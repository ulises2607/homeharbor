import { useCallback, useEffect, useState } from 'react';
import { apiRequest, errorMessage } from './api';

export default function useResource(path) {
  const [state, setState] = useState({ data: null, meta: null, loading: true, error: '' });
  const [revision, setRevision] = useState(0);
  const reload = useCallback(() => setRevision(value => value + 1), []);
  useEffect(() => {
    const controller = new AbortController();
    setState({ data: null, meta: null, loading: true, error: '' });
    apiRequest(path, { signal: controller.signal })
      .then(response => { if (!controller.signal.aborted) setState({ ...response, loading: false, error: '' }); })
      .catch(error => { if (!controller.signal.aborted) setState({ data: null, loading: false, error: errorMessage(error) }); });
    return () => controller.abort();
  }, [path, revision]);
  return { ...state, reload };
}
