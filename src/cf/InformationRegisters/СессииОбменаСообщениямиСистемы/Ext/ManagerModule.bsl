﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область СлужебныеПроцедурыИФункции

// Создает новую сессию обмена сообщениями и возвращает ее идентификатор
//
Функция НоваяСессия() Экспорт
	
	Сессия = Новый УникальныйИдентификатор;
	
	СтруктураЗаписи = Новый Структура("Сессия, ДатаНачала", Сессия, ТекущаяУниверсальнаяДата());
	
	ДобавитьЗапись(СтруктураЗаписи);
	
	Возврат Сессия;
КонецФункции

// Получает статус сессии: Выполняется, Успешно, Ошибка.
//
Функция СтатусСессии(Знач Сессия) Экспорт
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	ВЫБОР
	|		КОГДА СессииОбменаСообщениямиСистемы.ЗавершенаСОшибкой
	|			ТОГДА ""Ошибка""
	|		КОГДА СессииОбменаСообщениямиСистемы.ЗавершенаУспешно
	|			ТОГДА ""Успешно""
	|		ИНАЧЕ ""Выполняется""
	|	КОНЕЦ КАК Результат
	|ИЗ
	|	РегистрСведений.СессииОбменаСообщениямиСистемы КАК СессииОбменаСообщениямиСистемы
	|ГДЕ
	|	СессииОбменаСообщениямиСистемы.Сессия = &Сессия";
	Запись = ЗаписьСессияОбменаСообщениями(ТекстЗапроса, Сессия);
	
	Возврат Запись.Результат;
	
КонецФункции

// Отмечает успешное выполнение сессии
//
Процедура ЗафиксироватьУспешноеВыполнениеСессии(Знач Сессия) Экспорт
	
	СтруктураЗаписи = Новый Структура;
	СтруктураЗаписи.Вставить("Сессия", Сессия);
	СтруктураЗаписи.Вставить("ЗавершенаУспешно", Истина);
	СтруктураЗаписи.Вставить("ЗавершенаСОшибкой", Ложь);
	
	ОбновитьЗапись(СтруктураЗаписи);
	
КонецПроцедуры

// Отмечает неуспешное выполнение сессии
//
Процедура ЗафиксироватьНеуспешноеВыполнениеСессии(Знач Сессия) Экспорт
	
	СтруктураЗаписи = Новый Структура;
	СтруктураЗаписи.Вставить("Сессия", Сессия);
	СтруктураЗаписи.Вставить("ЗавершенаУспешно", Ложь);
	СтруктураЗаписи.Вставить("ЗавершенаСОшибкой", Истина);
	
	ОбновитьЗапись(СтруктураЗаписи);
	
КонецПроцедуры

// Сохраняет данные сессии и отмечает успешное выполнение сессии
//
Процедура СохранитьДанныеСессии(Знач Сессия, Данные) Экспорт
	
	СтруктураЗаписи = Новый Структура;
	СтруктураЗаписи.Вставить("Сессия", Сессия);
	СтруктураЗаписи.Вставить("Данные", Данные);
	СтруктураЗаписи.Вставить("ЗавершенаУспешно", Истина);
	СтруктураЗаписи.Вставить("ЗавершенаСОшибкой", Ложь);
	ОбновитьЗапись(СтруктураЗаписи);
	
КонецПроцедуры

// Получает данные сессии и удаляет сессию из информационной базы
//
Функция ПолучитьДанныеСессии(Знач Сессия) Экспорт
	
	ТекстЗапроса =
	"ВЫБРАТЬ
	|	СессииОбменаСообщениямиСистемы.Данные КАК Данные
	|ИЗ
	|	РегистрСведений.СессииОбменаСообщениямиСистемы КАК СессииОбменаСообщениямиСистемы
	|ГДЕ
	|	СессииОбменаСообщениямиСистемы.Сессия = &Сессия";
	
	НачатьТранзакцию();
	Попытка
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.СессииОбменаСообщениямиСистемы");
		ЭлементБлокировки.УстановитьЗначение("Сессия", Сессия);
		Блокировка.Заблокировать();
		
		Запись = ЗаписьСессияОбменаСообщениями(ТекстЗапроса, Сессия);
		
		Результат = Запись.Данные;
		
		УдалитьЗапись(Сессия);
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;
	
	Возврат Результат;
	
КонецФункции

// Вспомогательные процедуры и функции

Функция ЗаписьСессияОбменаСообщениями(ТекстЗапроса, Сессия)
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.УстановитьПараметр("Сессия", Сессия);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Не Выборка.Следующий() Тогда
		ВызватьИсключение СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Сессия обмена сообщениями системы ""%1"" не найдена.'"),
			Строка(Сессия));
	КонецЕсли;
	
	Возврат Выборка;
	
КонецФункции

Процедура ДобавитьЗапись(СтруктураЗаписи)
	
	ОбменДаннымиСлужебный.ДобавитьЗаписьВРегистрСведений(СтруктураЗаписи, "СессииОбменаСообщениямиСистемы");
	
КонецПроцедуры

Процедура ОбновитьЗапись(СтруктураЗаписи)
	
	ОбменДаннымиСлужебный.ОбновитьЗаписьВРегистрСведений(СтруктураЗаписи, "СессииОбменаСообщениямиСистемы");
	
КонецПроцедуры

Процедура УдалитьЗапись(Знач Сессия)
	
	ОбменДаннымиСлужебный.УдалитьНаборЗаписейВРегистреСведений(Новый Структура("Сессия", Сессия), "СессииОбменаСообщениямиСистемы");
	
КонецПроцедуры

#КонецОбласти

#КонецЕсли