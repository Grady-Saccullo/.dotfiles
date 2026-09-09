// State machines are pure: (entities, event) -> actions. They rebuild
// themselves from entity truth on every resync, so a daemon restart or an
// HA restart never leaves them believing something the house does not.
import type { HassEntity } from "home-assistant-js-websocket";

export interface Action {
  domain: string;
  service: string;
  data?: Record<string, unknown>;
  target?: { entity_id?: string | string[]; area_id?: string };
}

export interface Machine {
  name: string;
  resync(entities: Map<string, HassEntity>): void;
  handle(event: any): Action[];
}

// Example: presence debounce. Away only after every tracked person has been
// away for twenty minutes; home immediately.
export function presence(persons: string[], awayAfterMs = 20 * 60_000): Machine {
  const away = new Map<string, number>();
  let houseAway = false;
  return {
    name: "presence",
    resync(entities) {
      away.clear();
      for (const p of persons) {
        const s = entities.get(p);
        if (s && s.state !== "home") away.set(p, Date.now());
      }
      houseAway = persons.every((p) => away.has(p));
    },
    handle(ev) {
      const d = ev?.data;
      if (!d || !persons.includes(d.entity_id)) return [];
      const state = d.new_state?.state;
      if (state === "home") {
        away.delete(d.entity_id);
        if (houseAway) {
          houseAway = false;
          return [{ domain: "script", service: "turn_on", target: { entity_id: "script.arrive_home" } }];
        }
        return [];
      }
      away.set(d.entity_id, Date.now());
      const allAway = persons.every((p) => away.has(p) && Date.now() - away.get(p)! >= awayAfterMs);
      if (allAway && !houseAway) {
        houseAway = true;
        return [{ domain: "script", service: "turn_on", target: { entity_id: "script.leave_home" } }];
      }
      return [];
    },
  };
}

export const machines: Machine[] = [presence(["person.grady"])];
