package com.inkdesk.inkdesk_api.common.entity;

import java.sql.Timestamp;
import java.util.UUID;

import com.inkdesk.inkdesk_api.common.enums.Estado_cita;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "citas")
@Data
public class citas {
    private UUID cliente_id; // foreign key
    private UUID tatuador_id; // foreign key
    private Timestamp fecha_inicio;
    private Timestamp fecha_final;

    private String zona_cuerpo;
    private String text;
    private Estado_cita estado_cita;

    private int precio_estimado;
    private int precio_final;
    private int anticipo;

    private String ubicacion;
    private boolean consentimiento_firmado;
}
